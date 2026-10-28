from __future__ import annotations

import importlib.metadata
import platform
import subprocess
import time
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Mapping

from .client import ApiClient, EvaluationError, Session, model_present
from .config import (
    ARTIFACTS_ROOT,
    DATASET_PATH,
    DEFAULT_TOP_K,
    GOLDEN_SET_PATH,
    METRIC_KEYS,
    REPO_ROOT,
    SUITE,
    TARGETS_PATH,
    USER_CONTROL_SOURCE_ID,
    Settings,
    load_settings,
)
from .dataset import (
    CorpusChunk,
    EvalDataset,
    EvalQuestion,
    context_prompt_text,
    context_within_budget,
    corpus_hash,
    estimate_tokens,
    load_dataset,
    load_golden_corpus,
    reference_contexts,
    sha256_file,
    validate_dataset,
)
from .metrics import MetricsError, compute_metrics
from .preflight import check_pure_rag_sentinel
from .report import aggregate, load_targets, write_outputs
from .seed import verify_seed, wait_for_index_visibility
from .sse import citation_compliant, is_abstention, parse_citations

DEFAULT_FINDINGS = (
    "本次评估强制 `AI_AGENT_ENABLED=false`，只覆盖纯 RAG 模式；默认 Agent 模式会把知识问题路由到"
    "数据库工具，答案不再由检索上下文驱动。",
    "已知缺陷（未在工具链中绕过）：`RagQueryController`/`AiCallerIdentity` 把部门身份折叠为字符串"
    " `\"DEPARTMENT\"`，而 `AclFilterService` 按真实部门名（如 `traffic-police`）匹配，"
    "使 DEPARTMENT 语料在真实接口下对任何人不可见；ACL 探针因此只覆盖 ROLE/USER。",
    "产品答案模型默认 `llama3.2`，裁判模型为 `qwen2.5:7b` 与 `bge-m3`；模型能力差异会直接影响"
    " faithfulness / answer_correctness 的绝对分值，横向比较时需固定裁判与数据集。",
)


@dataclass(frozen=True)
class RunOptions:
    top_k: int = DEFAULT_TOP_K
    limit: int | None = None
    output_root: Path = ARTIFACTS_ROOT
    run_id: str | None = None
    max_workers: int = 2
    metric_timeout: int = 300
    max_retries: int = 2
    chat_timeout: float = 300.0
    enforce: bool = False


@dataclass
class RunResult:
    run_dir: Path
    manifest: dict[str, Any]
    result: dict[str, Any]
    hard_failures: list[str]
    answerable: list[dict[str, Any]]
    unanswerable: list[dict[str, Any]]
    acl_probes: list[dict[str, Any]]


def load_eval_dataset() -> EvalDataset:
    corpus = load_golden_corpus(GOLDEN_SET_PATH)
    dataset = load_dataset(DATASET_PATH, corpus)
    errors = validate_dataset(dataset)
    if errors:
        raise EvaluationError("evaluation dataset is invalid:\n- " + "\n- ".join(errors))
    return dataset


def run_evaluation(options: RunOptions | None = None) -> RunResult:
    options = options or RunOptions()
    settings = load_settings(top_k=options.top_k)
    dataset = load_eval_dataset()
    targets = load_targets(TARGETS_PATH)
    if options.enforce:
        targets["enforce"] = True

    answerable_questions = _select(dataset.questions, "answerable", options.limit)
    unanswerable_questions = _select(dataset.questions, "unanswerable", options.limit)
    acl_questions = _select(dataset.questions, "acl_probe", options.limit)

    with ApiClient(
            settings.base_url,
            es_url=settings.es_url,
            ollama_url=settings.ollama_url,
    ) as client:
        driver = client.login(settings.driver_username, settings.driver_password)
        admin = client.login(settings.admin_username, settings.admin_password)
        documents = verify_seed(client, admin, dataset.corpus)
        _require_judge_models(client, settings)
        client.es_refresh()
        wait_for_index_visibility(client, settings.index_alias, list(documents))

        sentinel = check_pure_rag_sentinel(client, driver, settings.top_k)
        if not sentinel.ok:
            raise EvaluationError(
                "pure-RAG sentinel failed: "
                + sentinel.detail
                + " (start the backend with AI_AGENT_ENABLED=false RAG_RETRIEVAL_ENABLED=true)"
            )

        control_visible = _user_control_visible(client, driver, settings.top_k)
        digests = _ollama_digests(client, settings)

        answerable = [
            _collect_answerable(client, driver, question, dataset.corpus, settings.top_k, options.chat_timeout)
            for question in answerable_questions
        ]
        unanswerable = [
            _collect_unanswerable(client, driver, question, settings.top_k, options.chat_timeout)
            for question in unanswerable_questions
        ]
        acl_probes = [
            _collect_acl_probe(client, driver, question, settings.top_k)
            for question in acl_questions
        ]

    metrics_error = _score_answerable(answerable, settings, options)

    result = aggregate(
        answerable,
        unanswerable,
        acl_probes,
        targets,
        metrics_error=metrics_error,
    )
    if not control_visible:
        result["hard_failures"].append(
            "USER ACL positive control document was not visible to the driver account"
        )
    failed_probes = [sample["id"] for sample in acl_probes if sample.get("error")]
    if failed_probes:
        result["hard_failures"].append(
            "ACL probe retrieval failed for: " + ", ".join(failed_probes)
        )

    run_id = options.run_id or _default_run_id()
    manifest = _manifest(
        run_id=run_id,
        settings=settings,
        dataset=dataset,
        documents=documents,
        digests=digests,
        control_visible=control_visible,
        options=options,
        metrics_error=metrics_error,
        counts={
            "answerable": len(answerable),
            "unanswerable": len(unanswerable),
            "acl_probe": len(acl_probes),
        },
    )
    run_dir = options.output_root / run_id
    write_outputs(
        run_dir,
        manifest=manifest,
        result=result,
        answerable=answerable,
        unanswerable=unanswerable,
        acl_probes=acl_probes,
        findings=_findings(),
    )
    return RunResult(
        run_dir=run_dir,
        manifest=manifest,
        result=result,
        hard_failures=list(result["hard_failures"]),
        answerable=answerable,
        unanswerable=unanswerable,
        acl_probes=acl_probes,
    )


def _select(
        questions: tuple[EvalQuestion, ...],
        kind: str,
        limit: int | None,
) -> list[EvalQuestion]:
    selected = [question for question in questions if question.kind == kind]
    if limit is not None:
        selected = selected[: max(0, limit)]
    return selected


def _collect_answerable(
        client: ApiClient,
        session: Session,
        question: EvalQuestion,
        corpus: Mapping[str, CorpusChunk],
        top_k: int,
        chat_timeout: float,
) -> dict[str, Any]:
    sample: dict[str, Any] = _base_sample(question)
    sample["reference"] = question.reference
    sample["reference_contexts"] = reference_contexts(question, corpus)
    sample["relevant_chunk_ids"] = list(question.relevant_chunk_ids)

    before = _retrieve(client, session, question, top_k, sample)
    if before is None:
        return _finalize_answerable(sample)

    sample["retrieved_chunk_ids"] = _source_ids(before)
    sample["retrieved_contexts"] = [str(result.get("content") or "") for result in before]
    sample["context_tokens"] = estimate_tokens(context_prompt_text(before))
    sample["within_budget"] = context_within_budget(before)
    sample["empty_context"] = not before

    _run_chat(client, session, question, sample, top_k, chat_timeout)
    _detect_drift(client, session, question, sample, top_k)
    return _finalize_answerable(sample)


def _collect_unanswerable(
        client: ApiClient,
        session: Session,
        question: EvalQuestion,
        top_k: int,
        chat_timeout: float,
) -> dict[str, Any]:
    sample = _base_sample(question)
    before = _retrieve(client, session, question, top_k, sample)
    if before is not None:
        sample["retrieved_chunk_ids"] = _source_ids(before)
        sample["context_tokens"] = estimate_tokens(context_prompt_text(before))
    _run_chat(client, session, question, sample, top_k, chat_timeout)
    sample["abstained"] = bool(sample.get("answer")) and is_abstention(sample.get("answer") or "")
    return sample


def _collect_acl_probe(
        client: ApiClient,
        session: Session,
        question: EvalQuestion,
        top_k: int,
) -> dict[str, Any]:
    sample = _base_sample(question)
    sample["must_not_return"] = list(question.must_not_return)
    try:
        results = client.rag_query(session, question.user_input, top_k)
    except EvaluationError as error:
        sample["error"] = f"retrieval failed: {error}"
        sample["retrieved_chunk_ids"] = []
        sample["leaked"] = False
        return sample
    source_ids = _source_ids(results)
    sample["retrieved_chunk_ids"] = source_ids
    sample["leaked"] = bool(set(question.must_not_return).intersection(source_ids))
    if question.id == "p02":
        sample["control_visible"] = USER_CONTROL_SOURCE_ID in source_ids
    return sample


def _base_sample(question: EvalQuestion) -> dict[str, Any]:
    return {
        "id": question.id,
        "kind": question.kind,
        "user_input": question.user_input,
        "multihop": question.multihop,
        "notes": question.notes,
        "answer": "",
        "event_types": [],
        "non_rag_events": [],
        "fallback": False,
        "guardrail_refusal": None,
        "citations": [],
        "citation_compliant": False,
        "retrieved_chunk_ids": [],
        "retrieved_contexts": [],
        "context_tokens": 0,
        "within_budget": True,
        "empty_context": True,
        "context_drift": False,
        "latency_ms": None,
        "error": None,
        "eligible": False,
        "scored": False,
        "exclusion_reason": None,
        "metrics": {key: None for key in METRIC_KEYS},
    }


def _retrieve(
        client: ApiClient,
        session: Session,
        question: EvalQuestion,
        top_k: int,
        sample: dict[str, Any],
) -> list[dict[str, Any]] | None:
    try:
        return client.rag_query(session, question.user_input, top_k)
    except EvaluationError as error:
        sample["error"] = f"retrieval failed: {error}"
        return None


def _run_chat(
        client: ApiClient,
        session: Session,
        question: EvalQuestion,
        sample: dict[str, Any],
        top_k: int,
        chat_timeout: float,
) -> None:
    started = time.perf_counter()
    try:
        response = client.chat_stream(
            session,
            question.user_input,
            {"ragTopK": top_k},
            timeout=chat_timeout,
        )
    except EvaluationError as error:
        sample["error"] = f"chat failed: {error}"
        sample["latency_ms"] = round((time.perf_counter() - started) * 1000, 1)
        return
    sample["latency_ms"] = round((time.perf_counter() - started) * 1000, 1)
    parse = response.parse
    sample["answer"] = parse.answer
    sample["event_types"] = sorted(set(parse.event_types))
    sample["non_rag_events"] = sorted(set(parse.non_rag_events))
    sample["fallback"] = parse.fallback
    sample["guardrail_refusal"] = parse.guardrail_refusal
    sample["citations"] = parse_citations(parse.answer)
    sample["citation_compliant"] = citation_compliant(
        parse.answer,
        len(sample.get("retrieved_chunk_ids") or []),
    )
    if parse.error and not sample["error"]:
        sample["error"] = f"chat stream error: {parse.error}"


def _detect_drift(
        client: ApiClient,
        session: Session,
        question: EvalQuestion,
        sample: dict[str, Any],
        top_k: int,
) -> None:
    try:
        after = client.rag_query(session, question.user_input, top_k)
    except EvaluationError as error:
        sample["context_drift"] = True
        sample["error"] = sample["error"] or f"retrieval after answer failed: {error}"
        return
    if _source_ids(after) != sample.get("retrieved_chunk_ids"):
        sample["context_drift"] = True


def _finalize_answerable(sample: dict[str, Any]) -> dict[str, Any]:
    sample["eligible"] = False
    if sample.get("error"):
        reason = "provider_error"
    elif sample.get("non_rag_events"):
        reason = "non_rag_events"
    elif sample.get("fallback"):
        reason = "provider_fallback"
    elif sample.get("context_drift"):
        reason = "context_drift"
    elif sample.get("empty_context"):
        reason = "empty_context"
    elif not sample.get("within_budget"):
        reason = "context_over_budget"
    elif sample.get("guardrail_refusal"):
        reason = f"guardrail_{sample['guardrail_refusal']}"
    elif not str(sample.get("answer") or "").strip():
        reason = "empty_answer"
    else:
        reason = None
    sample["exclusion_reason"] = reason
    sample["eligible"] = reason is None
    return sample


def _score_answerable(
        answerable: list[dict[str, Any]],
        settings: Settings,
        options: RunOptions,
) -> str | None:
    eligible = [sample for sample in answerable if sample.get("eligible")]
    if not eligible:
        return None
    records = [
        {
            "user_input": sample["user_input"],
            "response": sample["answer"],
            "retrieved_contexts": sample["retrieved_contexts"],
            "reference": sample["reference"],
        }
        for sample in eligible
    ]
    try:
        rows = compute_metrics(
            records,
            settings,
            max_workers=options.max_workers,
            timeout=options.metric_timeout,
            max_retries=options.max_retries,
        )
    except MetricsError as error:
        for sample in eligible:
            sample["exclusion_reason"] = "metrics_error"
            sample["eligible"] = False
        return str(error)

    for sample, row in zip(eligible, rows):
        sample["metrics"] = row
        sample["scored"] = any(row.get(key) is not None for key in METRIC_KEYS)
        if not sample["scored"]:
            sample["exclusion_reason"] = "metrics_empty"
    return None


def _source_ids(results: list[Mapping[str, Any]]) -> list[str]:
    return [str(result.get("sourceId") or "") for result in results]


def _require_judge_models(client: ApiClient, settings: Settings) -> None:
    tags = client.ollama_tags()
    for label, model in (
            ("RAGAS judge model", settings.judge_model),
            ("RAGAS embedding model", settings.judge_embedding_model),
            ("product embedding model", settings.product_embedding_model),
    ):
        if not model_present(tags, model):
            raise EvaluationError(
                f"{label} {model!r} is not installed in Ollama; run `ollama pull {model}`"
            )


def _user_control_visible(client: ApiClient, driver: Session, top_k: int) -> bool:
    """Query the full API cap: this proves ACL visibility, not top-5 ranking quality."""
    query = "我的违法记录（评测控制）"
    results = client.rag_query(driver, query, max(50, top_k))
    return USER_CONTROL_SOURCE_ID in _source_ids(results)


def _ollama_digests(client: ApiClient, settings: Settings) -> dict[str, str]:
    try:
        models = client.ollama_models()
    except EvaluationError:
        return {}
    wanted = {
        settings.answer_model,
        settings.judge_model,
        settings.judge_embedding_model,
        settings.product_embedding_model,
    }
    digests: dict[str, str] = {}
    for model in models:
        name = str(model.get("name") or "")
        if not name:
            continue
        for candidate in wanted:
            if name == candidate or name.startswith(candidate + ":"):
                digests[name] = str(model.get("digest") or "")
    return digests


def _manifest(
        *,
        run_id: str,
        settings: Settings,
        dataset: EvalDataset,
        documents: Mapping[str, str],
        digests: Mapping[str, str],
        control_visible: bool,
        options: RunOptions,
        metrics_error: str | None,
        counts: Mapping[str, int],
) -> dict[str, Any]:
    return {
        "run_id": run_id,
        "timestamp": datetime.now(timezone.utc).isoformat(timespec="seconds"),
        "git_commit": _git(["rev-parse", "HEAD"]),
        "git_dirty": bool(_git(["status", "--porcelain"])),
        "base_url": settings.base_url,
        "target": settings.target_label,
        "answer_mode": "pure-rag",
        "answer_model": settings.answer_model,
        "judge_model": settings.judge_model,
        "judge_embedding_model": settings.judge_embedding_model,
        "product_embedding_model": settings.product_embedding_model,
        "ragas_version": _package_version("ragas"),
        "python": platform.python_version(),
        "platform": platform.platform(),
        "top_k": options.top_k,
        "limit": options.limit,
        "enforce": bool(options.enforce),
        "dataset_hash": sha256_file(DATASET_PATH),
        "golden_set_hash": sha256_file(GOLDEN_SET_PATH),
        "corpus_hash": corpus_hash(dataset.corpus),
        "suite": SUITE,
        "document_count": len(documents),
        "control_visible": control_visible,
        "ollama_models": dict(sorted(digests.items())),
        "counts": dict(counts),
        "metrics_error": metrics_error,
        "notes": "Server must run with AI_AGENT_ENABLED=false and RAG_RETRIEVAL_ENABLED=true.",
    }


def _findings() -> list[str]:
    return list(DEFAULT_FINDINGS)


def _default_run_id() -> str:
    stamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    commit = (_git(["rev-parse", "--short=8", "HEAD"]) or "unknown").strip() or "unknown"
    return f"{stamp}-{commit}"


def _git(args: list[str]) -> str:
    try:
        completed = subprocess.run(
            ["git", *args],
            cwd=REPO_ROOT,
            capture_output=True,
            text=True,
            timeout=15,
            check=False,
        )
    except (OSError, subprocess.SubprocessError):
        return ""
    if completed.returncode != 0:
        return ""
    return completed.stdout.strip()


def _package_version(name: str) -> str:
    try:
        return importlib.metadata.version(name)
    except importlib.metadata.PackageNotFoundError:
        return "unknown"
