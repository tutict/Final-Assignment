from __future__ import annotations

import json
import time
from dataclasses import dataclass
from typing import Any, Mapping

from .client import ApiClient, Session
from .config import (
    SUITE,
    SOURCE_VERSION,
    USER_CONTROL_CONTENT,
    USER_CONTROL_SOURCE_ID,
    USER_CONTROL_TITLE,
)
from .dataset import CorpusChunk

FAILED_EMBEDDING_STATUSES = {"POISONED"}
DONE_EMBEDDING_STATUS = "SUCCEEDED"


@dataclass(frozen=True)
class SeedResult:
    documents: Mapping[str, str]
    control_document_id: str
    chunk_count: int


def build_payload(chunk: CorpusChunk) -> dict[str, Any]:
    metadata = {
        "suite": SUITE,
        "goldenDocumentId": chunk.document_id,
        "sourceType": chunk.source_type,
        "aclRoles": list(chunk.acl_roles),
        "userIds": list(chunk.acl_user_ids),
        "aclDepartments": list(chunk.acl_departments),
    }
    return {
        "sourceId": chunk.chunk_id,
        "sourceVersion": SOURCE_VERSION,
        "title": chunk.title,
        "content": chunk.content,
        "aclScope": chunk.acl_scope,
        "route": chunk.route,
        "metadataJson": json.dumps(metadata, ensure_ascii=False),
    }


def build_control_payload(driver_username: str) -> dict[str, Any]:
    metadata = {
        "suite": SUITE,
        "control": True,
        "userIds": [driver_username],
    }
    return {
        "sourceId": USER_CONTROL_SOURCE_ID,
        "sourceVersion": SOURCE_VERSION,
        "title": USER_CONTROL_TITLE,
        "content": USER_CONTROL_CONTENT,
        "aclScope": "USER",
        "route": "/user/offense",
        "metadataJson": json.dumps(metadata, ensure_ascii=False),
    }


def seed_corpus(
        client: ApiClient,
        admin: Session,
        corpus: Mapping[str, CorpusChunk],
        driver_username: str,
        *,
        timeout_seconds: float = 300.0,
        poll_seconds: float = 2.0,
) -> SeedResult:
    documents: dict[str, str] = {}
    for chunk_id in sorted(corpus):
        response = client.create_manual_document(admin, build_payload(corpus[chunk_id]))
        documents[chunk_id] = str(response["document"]["id"])
    control = client.create_manual_document(admin, build_control_payload(driver_username))
    control_id = str(control["document"]["id"])
    documents[USER_CONTROL_SOURCE_ID] = control_id

    wait_for_embeddings(client, admin, documents, timeout_seconds=timeout_seconds, poll_seconds=poll_seconds)
    client.es_refresh()
    return SeedResult(
        documents=documents,
        control_document_id=control_id,
        chunk_count=len(documents),
    )


def wait_for_embeddings(
        client: ApiClient,
        admin: Session,
        documents: Mapping[str, str],
        *,
        timeout_seconds: float = 300.0,
        poll_seconds: float = 2.0,
) -> None:
    deadline = time.monotonic() + timeout_seconds
    completed: set[str] = set()
    last_state: dict[str, list[str]] = {}
    while time.monotonic() < deadline:
        client.run_embedding_batch(admin, limit=50)
        for source_id, document_id in documents.items():
            if source_id in completed:
                continue
            detail = client.get_document(admin, document_id)
            chunks = detail.get("chunks") or []
            statuses = [str(chunk.get("embeddingStatus") or "") for chunk in chunks]
            last_state[source_id] = statuses
            if not chunks:
                raise RuntimeError(f"seed document {source_id} produced no chunks")
            for chunk, status in zip(chunks, statuses):
                if status in FAILED_EMBEDDING_STATUSES:
                    error = chunk.get("lastError") or "embedding task poisoned"
                    raise RuntimeError(f"embedding for {source_id} failed: {error}")
            if all(status == DONE_EMBEDDING_STATUS for status in statuses):
                completed.add(source_id)
        if len(completed) == len(documents):
            return
        time.sleep(poll_seconds)
    pending = {source_id: statuses for source_id, statuses in last_state.items() if source_id not in completed}
    raise RuntimeError(f"embedding tasks did not finish in {timeout_seconds:.0f}s: {pending}")


def wait_for_index_visibility(
        client: ApiClient,
        index_alias: str,
        source_ids: list[str],
        *,
        timeout_seconds: float = 90.0,
        poll_seconds: float = 3.0,
) -> None:
    """Prove every seeded sourceId is searchable without assuming semantic ranking quality."""
    deadline = time.monotonic() + timeout_seconds
    last_counts: dict[str, int] = {}
    while time.monotonic() < deadline:
        last_counts = client.es_source_counts(index_alias, source_ids)
        missing = [source_id for source_id in source_ids if last_counts.get(source_id, 0) < 1]
        if not missing:
            return
        time.sleep(poll_seconds)
    missing = [source_id for source_id in source_ids if last_counts.get(source_id, 0) < 1]
    raise RuntimeError(
        f"seeded sourceIds were not visible in index alias {index_alias!r} within "
        f"{timeout_seconds:.0f}s: {missing}; check rag.index.alias and the ES refresh interval"
    )


def verify_seed(
        client: ApiClient,
        admin: Session,
        corpus: Mapping[str, CorpusChunk],
) -> dict[str, str]:
    """Return sourceId -> documentId after proving every RAGAS document is fully embedded."""
    page = client.list_documents(admin, query=SUITE, size=100)
    documents: dict[str, str] = {}
    for item in page.get("items") or []:
        metadata = _metadata(item.get("metadataJson"))
        if metadata.get("suite") != SUITE:
            continue
        source_id = str(item.get("sourceId") or "")
        document_id = str(item.get("id") or "")
        if source_id and document_id:
            documents[source_id] = document_id

    expected = [*corpus, USER_CONTROL_SOURCE_ID]
    missing = sorted(source_id for source_id in expected if source_id not in documents)
    if missing:
        raise RuntimeError(
            "seeded RAGAS documents are missing: "
            + ", ".join(missing)
            + "; run `uv run ragas-eval seed`"
        )

    pending: dict[str, list[str]] = {}
    for source_id in expected:
        detail = client.get_document(admin, documents[source_id])
        chunks = detail.get("chunks") or []
        if not chunks:
            raise RuntimeError(f"document {source_id} produced no chunks; run `uv run ragas-eval seed`")
        statuses = [str(chunk.get("embeddingStatus") or "") for chunk in chunks]
        for chunk, status in zip(chunks, statuses):
            if status in FAILED_EMBEDDING_STATUSES:
                error = chunk.get("lastError") or "embedding task poisoned"
                raise RuntimeError(f"embedding for {source_id} failed: {error}")
        if not all(status == DONE_EMBEDDING_STATUS for status in statuses):
            pending[source_id] = statuses
    if pending:
        raise RuntimeError(
            "seeded documents are not fully embedded: "
            + json.dumps(pending, ensure_ascii=False)
            + "; run `uv run ragas-eval seed`"
        )
    return documents


def cleanup_suite_documents(client: ApiClient, admin: Session) -> list[str]:
    page = client.list_documents(admin, query=SUITE, size=100)
    deleted: list[str] = []
    for item in page.get("items") or []:
        metadata = _metadata(item.get("metadataJson"))
        if metadata.get("suite") != SUITE:
            continue
        document_id = str(item.get("id") or "")
        if document_id:
            client.delete_document(admin, document_id)
            deleted.append(document_id)
    client.es_refresh()
    return deleted


def _metadata(raw: Any) -> dict[str, Any]:
    if not raw:
        return {}
    try:
        parsed = json.loads(raw)
    except (TypeError, ValueError):
        return {}
    return parsed if isinstance(parsed, dict) else {}
