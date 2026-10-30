from __future__ import annotations

import argparse
from pathlib import Path

from .client import ApiClient, EvaluationError
from .config import ARTIFACTS_ROOT, DEFAULT_TOP_K, TARGETS_PATH, load_settings
from .preflight import run_preflight
from .report import load_targets
from .runner import RunOptions, load_eval_dataset, run_evaluation
from .seed import (
    cleanup_suite_documents,
    seed_corpus,
    verify_seed,
    wait_for_index_visibility,
)


def main(argv: list[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    try:
        if args.command == "validate":
            return command_validate()
        if args.command == "preflight":
            return command_preflight()
        if args.command == "seed":
            return command_seed(args)
        if args.command == "run":
            return command_run(args)
        if args.command == "all":
            return command_all(args)
    except EvaluationError as error:
        print(f"[FAIL] {error}")
        return 1
    parser.print_help()
    return 2


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="ragas-eval",
        description="Offline RAGAS answer-quality evaluation for the Spring backend",
    )
    subparsers = parser.add_subparsers(dest="command", required=True)

    subparsers.add_parser("validate", help="validate the dataset against the golden corpus")
    subparsers.add_parser("preflight", help="check runtime, logins, models, ES and pure-RAG mode")

    seed = subparsers.add_parser("seed", help="seed the golden corpus and wait for embeddings")
    _add_seed_arguments(seed)

    run = subparsers.add_parser("run", help="collect answers and compute RAGAS metrics")
    _add_run_arguments(run)

    all_command = subparsers.add_parser("all", help="preflight, seed and run in one go")
    _add_seed_arguments(all_command, include_top_k=False)
    _add_run_arguments(all_command)
    return parser


def _add_seed_arguments(parser: argparse.ArgumentParser, *, include_top_k: bool = True) -> None:
    if include_top_k:
        parser.add_argument("--top-k", type=int, default=DEFAULT_TOP_K, help="retrieval topK (default: 10)")
    parser.add_argument(
        "--cleanup",
        action="store_true",
        help="delete existing documents whose metadataJson.suite == 'ragas' before seeding",
    )


def _add_run_arguments(parser: argparse.ArgumentParser) -> None:
    parser.add_argument("--top-k", type=int, default=DEFAULT_TOP_K, help="retrieval topK (default: 10)")
    parser.add_argument("--limit", type=int, default=None, help="limit questions per kind (smoke runs)")
    parser.add_argument("--output", type=Path, default=ARTIFACTS_ROOT, help="artifact root directory")
    parser.add_argument("--run-id", default=None, help="override the generated run id")
    parser.add_argument("--max-workers", type=int, default=2, help="RAGAS judge worker count")
    parser.add_argument("--metric-timeout", type=int, default=300, help="RAGAS per-call timeout (s)")
    parser.add_argument("--max-retries", type=int, default=2, help="RAGAS judge retries")
    parser.add_argument("--chat-timeout", type=float, default=300.0, help="chat SSE timeout (s)")
    parser.add_argument(
        "--enforce",
        action="store_true",
        help="turn advisory score targets into hard failures",
    )


def command_validate() -> int:
    dataset = load_eval_dataset()
    targets = load_targets(TARGETS_PATH)
    counts = {kind: 0 for kind in ("answerable", "unanswerable", "acl_probe")}
    for question in dataset.questions:
        counts[question.kind] = counts.get(question.kind, 0) + 1
    public_ids = {
        chunk_id
        for chunk_id, chunk in dataset.corpus.items()
        if chunk.acl_scope == "PUBLIC"
    }
    covered = {
        chunk_id
        for question in dataset.questions
        if question.kind == "answerable"
        for chunk_id in question.relevant_chunk_ids
    }
    print(f"[OK] dataset valid: {counts}")
    print(f"[OK] golden chunks: {len(dataset.corpus)} (PUBLIC={len(public_ids)})")
    print(f"[OK] PUBLIC coverage: {len(covered & public_ids)}/{len(public_ids)}")
    print(f"[OK] targets: {TARGETS_PATH} (enforce={targets.get('enforce')})")
    return 0


def command_preflight() -> int:
    settings = load_settings()
    with ApiClient(settings.base_url, es_url=settings.es_url, ollama_url=settings.ollama_url) as client:
        checks, _ = run_preflight(client, settings)
    return 0 if _print_checks(checks) else 1


def command_seed(args: argparse.Namespace) -> int:
    settings = load_settings(top_k=args.top_k)
    dataset = load_eval_dataset()
    with ApiClient(settings.base_url, es_url=settings.es_url, ollama_url=settings.ollama_url) as client:
        driver = client.login(settings.driver_username, settings.driver_password)
        admin = client.login(settings.admin_username, settings.admin_password)
        if args.cleanup:
            deleted = cleanup_suite_documents(client, admin)
            print(f"[OK] cleanup removed {len(deleted)} RAGAS documents")
        seeded = seed_corpus(client, admin, dataset.corpus, driver.username)
        print(f"[OK] seeded {seeded.chunk_count} documents")
        wait_for_index_visibility(client, settings.index_alias, list(seeded.documents))
        _require_retrieval_context(client, driver, settings.top_k)
        documents = verify_seed(client, admin, dataset.corpus)
        print(f"[OK] all {len(documents)} seeded documents are embedded and searchable")
    return 0


def command_run(args: argparse.Namespace) -> int:
    result = run_evaluation(_run_options(args))
    _print_run_summary(result)
    return 0 if not result.hard_failures else 1


def command_all(args: argparse.Namespace) -> int:
    if command_validate() != 0:
        return 1
    settings = load_settings(top_k=args.top_k)
    dataset = load_eval_dataset()
    with ApiClient(settings.base_url, es_url=settings.es_url, ollama_url=settings.ollama_url) as client:
        checks, _ = run_preflight(client, settings, check_sentinel=False)
        if not _print_checks(checks):
            return 1
        driver = client.login(settings.driver_username, settings.driver_password)
        admin = client.login(settings.admin_username, settings.admin_password)
        if args.cleanup:
            deleted = cleanup_suite_documents(client, admin)
            print(f"[OK] cleanup removed {len(deleted)} RAGAS documents")
        seeded = seed_corpus(client, admin, dataset.corpus, driver.username)
        print(f"[OK] seeded {seeded.chunk_count} documents")
        wait_for_index_visibility(client, settings.index_alias, list(seeded.documents))
        _require_retrieval_context(client, driver, settings.top_k)
        verify_seed(client, admin, dataset.corpus)

    result = run_evaluation(_run_options(args))
    _print_run_summary(result)
    return 0 if not result.hard_failures else 1


def _run_options(args: argparse.Namespace) -> RunOptions:
    return RunOptions(
        top_k=max(1, args.top_k),
        limit=args.limit,
        output_root=args.output,
        run_id=args.run_id,
        max_workers=max(1, args.max_workers),
        metric_timeout=max(1, args.metric_timeout),
        max_retries=max(0, args.max_retries),
        chat_timeout=max(30.0, args.chat_timeout),
        enforce=bool(args.enforce),
    )


def _require_retrieval_context(client, driver, top_k: int) -> None:
    results = client.rag_query(driver, "罚款怎么缴纳", top_k)
    if not results:
        raise EvaluationError(
            "POST /api/rag/query returned no context after seeding; "
            "check RAG_RETRIEVAL_ENABLED=true and the configured index alias"
        )


def _print_checks(checks) -> bool:
    for check in checks:
        status = "PASS" if check.ok else "FAIL"
        print(f"[{status}] {check.name}: {check.detail}")
    return all(check.ok for check in checks)


def _print_run_summary(result) -> None:
    metrics = result.result["metrics"]
    print("")
    print(f"[RESULT] artifacts: {result.run_dir}")
    print(
        f"[RESULT] answerable={result.result['answerable_samples']} "
        f"scored={result.result['scored_samples']} "
        f"coverage={result.result['scored_coverage']:.2%}"
    )
    for key, metric in metrics.items():
        mean = metric["mean"]
        rendered = "n/a" if mean is None else f"{mean:.4f}"
        print(f"[METRIC] {key}: {rendered} (target={metric['target']}, meets={metric['meets_target']})")
    print(
        f"[RESULT] citation_compliance={_fmt(result.result['citation_compliance'])} "
        f"citation_compliance_all={_fmt(result.result['citation_compliance_all'])} "
        f"guardrail_refusals={result.result['guardrail_refusal_count']} "
        f"fallback_rate={_fmt(result.result['fallback_rate'])} "
        f"acl_leaks={result.result['acl']['leaked']} "
        f"drift={result.result['context_drift_count']}"
    )
    if result.result.get("metrics_error"):
        print(f"[FAIL] RAGAS scoring error: {result.result['metrics_error']}")
    if result.hard_failures:
        for failure in result.hard_failures:
            print(f"[FAIL] {failure}")
    else:
        print("[PASS] no hard failures")


def _fmt(value) -> str:
    return "-" if value is None else f"{float(value):.4f}"
