from __future__ import annotations

from dataclasses import dataclass
from typing import Any

import httpx

from .sse import ChatParseResult, parse_chat_events, parse_sse


class EvaluationError(RuntimeError):
    pass


class ApiError(EvaluationError):
    pass


@dataclass(frozen=True)
class Session:
    username: str
    token: str
    roles: tuple[str, ...]


@dataclass(frozen=True)
class ChatResponse:
    parse: ChatParseResult
    raw: str


class ApiClient:
    def __init__(
            self,
            base_url: str,
            *,
            es_url: str = "http://localhost:9200",
            ollama_url: str = "http://localhost:11434",
            timeout: float = 60.0,
    ) -> None:
        # The harness only talks to local dev services; ignore ambient proxy settings so a
        # developer's SOCKS proxy cannot intercept localhost traffic.
        self._http = httpx.Client(
            base_url=base_url.rstrip("/"), timeout=timeout, follow_redirects=True, trust_env=False
        )
        self._es = httpx.Client(
            base_url=es_url.rstrip("/"), timeout=timeout, follow_redirects=True, trust_env=False
        )
        self._ollama = httpx.Client(
            base_url=ollama_url.rstrip("/"), timeout=timeout, follow_redirects=True, trust_env=False
        )

    def close(self) -> None:
        self._http.close()
        self._es.close()
        self._ollama.close()

    def __enter__(self) -> "ApiClient":
        return self

    def __exit__(self, *_: object) -> None:
        self.close()

    def login(self, username: str, password: str) -> Session:
        response = self._request(
            self._http,
            "POST",
            "/api/auth/login",
            label="POST /api/auth/login",
            json={"username": username, "password": password},
        )
        if response.status_code == 429:
            retry_after = response.headers.get("Retry-After", "unknown")
            raise ApiError(f"login throttled for {username}; retry after {retry_after}s")
        if response.status_code != 200:
            raise ApiError(f"login failed for {username}: HTTP {response.status_code} {response.text[:300]}")
        body = response.json()
        token = body.get("jwtToken") or body.get("accessToken")
        if not token:
            raise ApiError(f"login for {username} returned no JWT token")
        roles = body.get("roleCodes") or body.get("roles") or []
        return Session(username=str(body.get("username") or username), token=str(token), roles=tuple(roles))

    def rag_query(self, session: Session, query: str, top_k: int) -> list[dict[str, Any]]:
        response = self._request(
            self._http,
            "POST",
            "/api/rag/query",
            label="POST /api/rag/query",
            json={"query": query, "topK": top_k},
            headers=_bearer(session),
        )
        payload = self._checked_json(response, "POST /api/rag/query")
        results = payload.get("results") if isinstance(payload, dict) else None
        if not isinstance(results, list):
            raise ApiError("POST /api/rag/query returned no results array")
        return results

    def chat_stream(
            self,
            session: Session,
            message: str,
            metadata: dict[str, Any] | None = None,
            *,
            timeout: float = 300.0,
    ) -> ChatResponse:
        request = {
            "message": message,
            "sessionKey": f"ragas-{session.username}-{abs(hash(message)) % 10_000_000}",
            "metadata": metadata or {},
        }
        try:
            with self._http.stream(
                    "POST",
                    "/api/ai/chat/stream",
                    json=request,
                    headers={**_bearer(session), "Accept": "text/event-stream"},
                    timeout=httpx.Timeout(timeout, connect=10.0),
            ) as response:
                if response.status_code != 200:
                    body = response.read().decode("utf-8", "replace")
                    raise ApiError(f"POST /api/ai/chat/stream failed: HTTP {response.status_code} {body[:500]}")
                chunks = list(response.iter_text())
        except httpx.HTTPError as error:
            raise ApiError(f"POST /api/ai/chat/stream transport error: {error}") from error
        raw = "".join(chunks)
        return ChatResponse(parse=parse_chat_events(parse_sse(raw)), raw=raw)

    def overview(self, session: Session) -> dict[str, Any]:
        response = self._request(
            self._http,
            "GET",
            "/api/rag/admin/overview",
            label="GET /api/rag/admin/overview",
            headers=_bearer(session),
        )
        return self._checked_json(response, "GET /api/rag/admin/overview")

    def create_manual_document(self, session: Session, payload: dict[str, Any]) -> dict[str, Any]:
        response = self._request(
            self._http,
            "POST",
            "/api/rag/admin/documents/manual",
            label="POST /api/rag/admin/documents/manual",
            json=payload,
            headers=_bearer(session),
        )
        return self._checked_json(response, "POST /api/rag/admin/documents/manual")

    def get_document(self, session: Session, document_id: str) -> dict[str, Any]:
        response = self._request(
            self._http,
            "GET",
            f"/api/rag/admin/documents/{document_id}",
            label=f"GET /api/rag/admin/documents/{document_id}",
            headers=_bearer(session),
        )
        return self._checked_json(response, f"GET /api/rag/admin/documents/{document_id}")

    def list_documents(self, session: Session, *, query: str = "", size: int = 200) -> dict[str, Any]:
        response = self._request(
            self._http,
            "GET",
            "/api/rag/admin/documents",
            label="GET /api/rag/admin/documents",
            params={"query": query, "size": size},
            headers=_bearer(session),
        )
        return self._checked_json(response, "GET /api/rag/admin/documents")

    def delete_document(self, session: Session, document_id: str) -> dict[str, Any]:
        response = self._request(
            self._http,
            "DELETE",
            f"/api/rag/admin/documents/{document_id}",
            label=f"DELETE /api/rag/admin/documents/{document_id}",
            headers=_bearer(session),
        )
        return self._checked_json(response, f"DELETE /api/rag/admin/documents/{document_id}")

    def run_embedding_batch(self, session: Session, limit: int = 50) -> dict[str, Any]:
        response = self._request(
            self._http,
            "POST",
            "/api/rag/admin/embedding/run",
            label="POST /api/rag/admin/embedding/run",
            params={"limit": limit},
            headers=_bearer(session),
        )
        return self._checked_json(response, "POST /api/rag/admin/embedding/run")

    def es_refresh(self) -> dict[str, Any]:
        response = self._request(self._es, "POST", "/_refresh", label="POST /_refresh")
        return self._checked_json(response, "POST /_refresh", unwrap=False)

    def es_source_counts(self, index: str, source_ids: list[str]) -> dict[str, int]:
        body = {
            "size": 0,
            "query": {"terms": {"source_id": source_ids}},
            "aggs": {"ids": {"terms": {"field": "source_id", "size": max(1, len(source_ids))}}},
        }
        response = self._request(
            self._es,
            "POST",
            f"/{index}/_search",
            label=f"POST /{index}/_search",
            json=body,
        )
        payload = self._checked_json(response, f"POST /{index}/_search", unwrap=False)
        buckets = (((payload.get("aggregations") or {}).get("ids") or {}).get("buckets") or [])
        counts: dict[str, int] = {}
        for bucket in buckets:
            if not isinstance(bucket, dict):
                continue
            key = str(bucket.get("key") or "")
            if key:
                counts[key] = int(bucket.get("doc_count") or 0)
        return counts

    def es_health(self) -> dict[str, Any]:
        response = self._request(self._es, "GET", "/_cluster/health", label="GET /_cluster/health")
        return self._checked_json(response, "GET /_cluster/health", unwrap=False)

    def ollama_models(self) -> list[dict[str, Any]]:
        response = self._request(self._ollama, "GET", "/api/tags", label="GET /api/tags")
        payload = self._checked_json(response, "GET /api/tags", unwrap=False)
        models = payload.get("models") if isinstance(payload, dict) else None
        if not isinstance(models, list):
            raise ApiError("GET /api/tags returned no models array")
        return [model for model in models if isinstance(model, dict)]

    def ollama_tags(self) -> list[str]:
        return [str(model.get("name") or "") for model in self.ollama_models()]

    @staticmethod
    def _request(
            client: httpx.Client,
            method: str,
            url: str,
            *,
            label: str,
            **kwargs: Any,
    ) -> httpx.Response:
        try:
            return client.request(method, url, **kwargs)
        except httpx.HTTPError as error:
            raise ApiError(f"{label} transport error: {error}") from error

    def _checked_json(self, response: httpx.Response, label: str, *, unwrap: bool = True) -> Any:
        if response.status_code >= 400:
            raise ApiError(f"{label} failed: HTTP {response.status_code} {response.text[:500]}")
        try:
            payload = response.json()
        except ValueError as error:
            raise ApiError(f"{label} returned non-JSON body: {response.text[:300]}") from error
        if isinstance(payload, dict) and payload.get("success") is False:
            code = payload.get("errorCode") or "ERROR"
            message = payload.get("message") or "request failed"
            raise ApiError(f"{label} failed: {code}: {message}")
        if unwrap and isinstance(payload, dict) and "data" in payload:
            return payload["data"]
        return payload


def model_present(tags: list[str], wanted: str) -> bool:
    wanted = wanted.strip()
    if not wanted:
        return False
    return any(tag == wanted or tag.startswith(wanted + ":") for tag in tags)


def _bearer(session: Session) -> dict[str, str]:
    return {"Authorization": f"Bearer {session.token}"}
