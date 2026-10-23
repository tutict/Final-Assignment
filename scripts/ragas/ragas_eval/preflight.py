from __future__ import annotations

import platform
from dataclasses import dataclass

from .client import ApiClient, Session, model_present
from .config import Settings
from .sse import citation_compliant


@dataclass(frozen=True)
class CheckResult:
    name: str
    ok: bool
    detail: str


def run_preflight(
        client: ApiClient,
        settings: Settings,
        *,
        check_sentinel: bool = True,
) -> tuple[list[CheckResult], dict[str, Session]]:
    checks: list[CheckResult] = []
    implementation = platform.python_implementation()
    checks.append(
        CheckResult(
            "CPython runtime",
            implementation == "CPython",
            f"{implementation} {platform.python_version()} (requires CPython 3.12 via uv)",
        )
    )

    driver = client.login(settings.driver_username, settings.driver_password)
    admin = client.login(settings.admin_username, settings.admin_password)
    checks.append(
        CheckResult(
            "Driver login",
            "ADMIN" not in driver.roles and "SUPER_ADMIN" not in driver.roles,
            f"{driver.username} roles={list(driver.roles)}",
        )
    )
    checks.append(
        CheckResult(
            "Admin login",
            bool({"ADMIN", "SUPER_ADMIN"}.intersection(admin.roles)),
            f"{admin.username} roles={list(admin.roles)}",
        )
    )

    overview = client.overview(admin)
    checks.append(
        CheckResult(
            "RAG enabled",
            bool(overview.get("ragEnabled")),
            f"ragEnabled={overview.get('ragEnabled')}",
        )
    )
    checks.append(
        CheckResult(
            "RAG indexing enabled",
            bool(overview.get("indexingEnabled")),
            f"indexingEnabled={overview.get('indexingEnabled')}",
        )
    )
    checks.append(
        CheckResult(
            "RAG corpus present",
            int(overview.get("chunkCount") or 0) > 0,
            f"documents={overview.get('documentCount')} chunks={overview.get('chunkCount')} "
            "(run `ragas-eval seed` if zero)",
        )
    )

    tags = client.ollama_tags()
    for label, model in (
            ("Product embedding model", settings.product_embedding_model),
            ("RAGAS judge model", settings.judge_model),
            ("RAGAS embedding model", settings.judge_embedding_model),
    ):
        present = model_present(tags, model)
        checks.append(
            CheckResult(
                label,
                present,
                f"{model} {'installed' if present else 'missing - run `ollama pull ' + model + '`'}",
            )
        )

    health = client.es_health()
    status = str(health.get("status") or "unknown").lower()
    checks.append(
        CheckResult("Elasticsearch health", status in {"yellow", "green"}, f"status={status}")
    )

    if check_sentinel and int(overview.get("chunkCount") or 0) > 0:
        checks.append(check_pure_rag_sentinel(client, driver, settings.top_k))
    else:
        checks.append(
            CheckResult(
                "Pure-RAG sentinel",
                True,
                "skipped until the golden corpus is seeded",
            )
        )

    return checks, {"driver": driver, "admin": admin}


def check_pure_rag_sentinel(client: ApiClient, driver: Session, top_k: int) -> CheckResult:
    query = "罚款怎么缴纳"
    results = client.rag_query(driver, query, top_k)
    if not results:
        return CheckResult(
            "Pure-RAG sentinel",
            False,
            "retrieval returned no context; check RAG_RETRIEVAL_ENABLED=true and the dev profile",
        )
    response = client.chat_stream(driver, query, {"ragTopK": top_k})
    parse = response.parse
    if parse.error:
        return CheckResult("Pure-RAG sentinel", False, f"chat failed: {parse.error}")
    if parse.non_rag_events:
        return CheckResult(
            "Pure-RAG sentinel",
            False,
            f"chat emitted {sorted(set(parse.non_rag_events))}; start the server with AI_AGENT_ENABLED=false",
        )
    if parse.guardrail_refusal:
        return CheckResult(
            "Pure-RAG sentinel",
            False,
            f"answer was replaced by the citation guardrail ({parse.guardrail_refusal})",
        )
    if not citation_compliant(parse.answer, len(results)):
        return CheckResult(
            "Pure-RAG sentinel",
            False,
            f"answer has no valid [n] citation: {parse.answer[:120]!r}",
        )
    return CheckResult(
        "Pure-RAG sentinel",
        True,
        f"contexts={len(results)} answer={parse.answer[:80]!r}",
    )
