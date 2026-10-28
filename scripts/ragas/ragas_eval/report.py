from __future__ import annotations

import json
from collections import Counter
from pathlib import Path
from typing import Any, Iterable, Mapping

from .config import METRIC_KEYS
from .metrics import mean

TARGET_LABELS = {
    "faithfulness": "Faithfulness",
    "response_relevancy": "Response Relevancy",
    "context_precision": "Context Precision (with reference)",
    "context_recall": "Context Recall",
    "answer_correctness": "Answer Correctness",
}


def aggregate(
        answerable: list[Mapping[str, Any]],
        unanswerable: list[Mapping[str, Any]],
        acl_probes: list[Mapping[str, Any]],
        targets: Mapping[str, Any],
        *,
        metrics_error: str | None = None,
) -> dict[str, Any]:
    scored = [sample for sample in answerable if sample.get("scored")]
    metric_means = {
        key: mean(sample.get("metrics", {}).get(key) for sample in scored) for key in METRIC_KEYS
    }
    metric_results = {
        key: {
            "mean": metric_means[key],
            "target": targets.get(key),
            "meets_target": _meets(metric_means[key], targets.get(key)),
        }
        for key in METRIC_KEYS
    }

    non_error = [sample for sample in answerable if not sample.get("error")]
    citation_compliance = mean(
        1.0 if sample.get("citation_compliant") else 0.0 for sample in non_error
    )
    fallback_rate = mean(
        1.0 if sample.get("fallback") else 0.0 for sample in answerable
    )
    exclusion_reasons = Counter(
        str(sample.get("exclusion_reason"))
        for sample in answerable
        if not sample.get("scored") and sample.get("exclusion_reason")
    )
    multihop = [sample for sample in answerable if sample.get("multihop")]
    multihop_scored = [sample for sample in multihop if sample.get("scored")]

    abstained = sum(1 for sample in unanswerable if sample.get("abstained"))
    leaks = sum(int(sample.get("leaked") or 0) for sample in acl_probes)
    scored_coverage = len(scored) / len(answerable) if answerable else 0.0
    abstention_rate = abstained / len(unanswerable) if unanswerable else None

    result = {
        "answerable_samples": len(answerable),
        "scored_samples": len(scored),
        "scored_coverage": scored_coverage,
        "metrics": metric_results,
        "citation_compliance": citation_compliance,
        "fallback_rate": fallback_rate,
        "context_drift_count": sum(1 for sample in answerable if sample.get("context_drift")),
        "provider_error_count": sum(1 for sample in answerable if sample.get("error")),
        "guardrail_refusal_count": sum(
            1 for sample in answerable if sample.get("guardrail_refusal")
        ),
        "exclusion_reasons": dict(sorted(exclusion_reasons.items())),
        "multihop": {
            "count": len(multihop),
            "scored_samples": len(multihop_scored),
            "metrics": {
                key: mean(sample.get("metrics", {}).get(key) for sample in multihop_scored)
                for key in METRIC_KEYS
            },
        },
        "unanswerable": {
            "total": len(unanswerable),
            "abstained": abstained,
            "abstention_rate": abstention_rate,
            "meets_target": _meets(abstention_rate, targets.get("min_unanswerable_abstention")),
        },
        "acl": {
            "total": len(acl_probes),
            "leaked": leaks,
            "passed": len(acl_probes) - leaks if acl_probes else 0,
        },
        "metrics_error": metrics_error,
        "targets": dict(targets),
    }
    result["hard_failures"] = hard_failures(result, targets)
    return result


def hard_failures(result: Mapping[str, Any], targets: Mapping[str, Any]) -> list[str]:
    failures: list[str] = []
    if result["acl"]["leaked"]:
        failures.append(f"ACL leakage detected in {result['acl']['leaked']} probe(s)")
    if result["context_drift_count"]:
        failures.append(f"context drift detected in {result['context_drift_count']} sample(s)")
    if result["provider_error_count"]:
        failures.append(f"provider errors in {result['provider_error_count']} sample(s)")
    if result.get("metrics_error"):
        failures.append(f"RAGAS scoring failed: {result['metrics_error']}")
    if not result["scored_samples"]:
        failures.append("no sample could be scored by RAGAS")

    if targets.get("enforce"):
        for key in METRIC_KEYS:
            value = result["metrics"][key]["mean"]
            target = targets.get(key)
            if value is None:
                failures.append(f"{key} could not be computed")
            elif target is not None and value < float(target):
                failures.append(f"{key}={value:.4f} below target {float(target):.4f}")
        minimum_coverage = targets.get("min_scored_coverage")
        if minimum_coverage is not None and result["scored_coverage"] < float(minimum_coverage):
            failures.append(
                f"scored coverage {result['scored_coverage']:.2f} below target {float(minimum_coverage):.2f}"
            )
        max_fallback = targets.get("max_fallback_rate")
        if max_fallback is not None and (result["fallback_rate"] or 0.0) > float(max_fallback):
            failures.append(
                f"fallback rate {result['fallback_rate']:.2f} above target {float(max_fallback):.2f}"
            )
        min_citation = targets.get("citation_compliance")
        if min_citation is not None and (result["citation_compliance"] or 0.0) < float(min_citation):
            failures.append(
                f"citation compliance {result['citation_compliance']:.2f} below target {float(min_citation):.2f}"
            )
        min_abstention = targets.get("min_unanswerable_abstention")
        if (
                min_abstention is not None
                and result["unanswerable"]["abstention_rate"] is not None
                and result["unanswerable"]["abstention_rate"] < float(min_abstention)
        ):
            failures.append(
                f"unanswerable abstention {result['unanswerable']['abstention_rate']:.2f} "
                f"below target {float(min_abstention):.2f}"
            )
    return failures


def render_markdown(
        manifest: Mapping[str, Any],
        result: Mapping[str, Any],
        answerable: list[Mapping[str, Any]],
        unanswerable: list[Mapping[str, Any]],
        acl_probes: list[Mapping[str, Any]],
        findings: Iterable[str],
) -> str:
    lines: list[str] = []
    lines.append("# RAGAS 答案质量基线报告")
    lines.append("")
    lines.append("## 环境")
    lines.append("")
    lines.append("| 项目 | 值 |")
    lines.append("| --- | --- |")
    rows = [
        ("运行 ID", manifest.get("run_id")),
        ("时间", manifest.get("timestamp")),
        ("Git commit", manifest.get("git_commit")),
    ]
    if manifest.get("target"):
        rows.append(("评估目标", manifest.get("target")))
    rows.extend((
        ("后端", manifest.get("base_url")),
        ("答案模型", manifest.get("answer_model")),
        ("裁判模型", manifest.get("judge_model")),
        ("裁判嵌入", manifest.get("judge_embedding_model")),
        ("topK", manifest.get("top_k")),
        ("数据集 hash", _short_hash(manifest.get("dataset_hash"))),
        ("语料 hash", _short_hash(manifest.get("corpus_hash"))),
    ))
    for key, value in rows:
        lines.append(f"| {key} | {value} |")
    lines.append("")
    lines.append("## 总表")
    lines.append("")
    lines.append("| 指标 | 均值 | 目标 | 结果 |")
    lines.append("| --- | ---: | ---: | --- |")
    for key in METRIC_KEYS:
        metric = result["metrics"][key]
        lines.append(
            f"| {TARGET_LABELS[key]} | {_fmt(metric['mean'])} | {_fmt(metric['target'])} | "
            f"{_status(metric['meets_target'])} |"
        )
    lines.append(
        f"| Citation compliance | {_fmt(result['citation_compliance'])} | "
        f"{_fmt(result['targets'].get('citation_compliance'))} | "
        f"{_status(_meets(result['citation_compliance'], result['targets'].get('citation_compliance')))} |"
    )
    lines.append(
        f"| Fallback rate | {_fmt(result['fallback_rate'])} | "
        f"≤ {_fmt(result['targets'].get('max_fallback_rate'))} | "
        f"{_status(_at_most(result['fallback_rate'], result['targets'].get('max_fallback_rate')))} |"
    )
    lines.append("")
    lines.append("评分目标在首轮为 advisory；只有 ACL 泄漏、上下文漂移、provider 错误与预检失败为硬失败。")
    if result.get("metrics_error"):
        lines.append("")
        lines.append(f"> RAGAS 评分失败：{result['metrics_error']}")
    lines.append("")
    lines.append("## 样本计数")
    lines.append("")
    lines.append("| 项目 | 值 |")
    lines.append("| --- | ---: |")
    lines.append(f"| 可回答题总数 | {result['answerable_samples']} |")
    lines.append(f"| 可评分样本 | {result['scored_samples']} |")
    lines.append(f"| 可评分覆盖率 | {result['scored_coverage']:.2%} |")
    lines.append(f"| 上下文漂移 | {result['context_drift_count']} |")
    lines.append(f"| Provider 错误 | {result['provider_error_count']} |")
    lines.append(f"| 引用护栏拒答 | {result['guardrail_refusal_count']} |")
    lines.append(f"| Fallback 次数 | {_fmt(result['fallback_rate'])} (比例) |")
    if result["exclusion_reasons"]:
        reasons = "、".join(f"{key}={value}" for key, value in result["exclusion_reasons"].items())
        lines.append(f"| 排除原因 | {reasons} |")
    lines.append("")
    if result["multihop"]["count"]:
        lines.append("## 多跳切片")
        lines.append("")
        lines.append("| 指标 | 均值 |")
        lines.append("| --- | ---: |")
        for key in METRIC_KEYS:
            lines.append(f"| {TARGET_LABELS[key]} | {_fmt(result['multihop']['metrics'][key])} |")
        lines.append("")
    lines.append("## 最差样例")
    lines.append("")
    worst = sorted(
        [sample for sample in answerable if sample.get("scored")],
        key=lambda sample: (
            sample.get("metrics", {}).get("answer_correctness")
            if sample.get("metrics", {}).get("answer_correctness") is not None
            else 1.0,
            sample.get("metrics", {}).get("faithfulness")
            if sample.get("metrics", {}).get("faithfulness") is not None
            else 1.0,
        ),
    )[:5]
    if not worst:
        lines.append("无可评分样例。")
    else:
        lines.append("| ID | 问题 | Faithfulness | Answer Correctness | 答案摘要 |")
        lines.append("| --- | --- | ---: | ---: | --- |")
        for sample in worst:
            lines.append(
                f"| {sample['id']} | {sample['user_input']} | "
                f"{_fmt(sample['metrics'].get('faithfulness'))} | "
                f"{_fmt(sample['metrics'].get('answer_correctness'))} | "
                f"{_snippet(sample.get('answer'))} |"
            )
    lines.append("")
    lines.append("## 不可回答问题")
    lines.append("")
    lines.append("| ID | 问题 | 是否拒答 | 检索到的 sourceId | 答案摘要 |")
    lines.append("| --- | --- | --- | --- | --- |")
    for sample in unanswerable:
        lines.append(
            f"| {sample['id']} | {sample['user_input']} | {'是' if sample.get('abstained') else '否'} | "
            f"{', '.join(sample.get('retrieved_chunk_ids') or []) or '-'} | {_snippet(sample.get('answer'))} |"
        )
    lines.append("")
    lines.append(
        f"不可回答拒答率：{result['unanswerable']['abstained']}/{result['unanswerable']['total']} "
        f"({_fmt_result(result['unanswerable']['abstention_rate'])})"
    )
    lines.append("")
    lines.append("## ACL 探针")
    lines.append("")
    lines.append("| ID | 问题 | 禁止返回 | 实际返回 | 结果 |")
    lines.append("| --- | --- | --- | --- | --- |")
    for sample in acl_probes:
        outcome = "LEAK" if sample.get("leaked") else ("ERROR" if sample.get("error") else "PASS")
        lines.append(
            f"| {sample['id']} | {sample['user_input']} | {', '.join(sample.get('must_not_return') or [])} | "
            f"{', '.join(sample.get('retrieved_chunk_ids') or []) or '-'} | {outcome} |"
        )
    lines.append("")
    lines.append(f"ACL 泄漏：{result['acl']['leaked']} / {result['acl']['total']} 个探针。")
    lines.append("")
    lines.append("## 硬失败")
    lines.append("")
    if result["hard_failures"]:
        for failure in result["hard_failures"]:
            lines.append(f"- {failure}")
    else:
        lines.append("- 无")
    lines.append("")
    lines.append("## 附带发现")
    lines.append("")
    for finding in findings:
        lines.append(f"- {finding}")
    lines.append("")
    lines.append("## 复现")
    lines.append("")
    lines.append("```bash")
    lines.append("cd scripts/ragas")
    lines.append("uv sync --frozen")
    lines.append("uv run ragas-eval validate")
    lines.append("uv run ragas-eval preflight")
    lines.append("uv run ragas-eval seed")
    lines.append(f"uv run ragas-eval run --top-k {manifest.get('top_k')}")
    lines.append("```")
    lines.append("")
    return "\n".join(lines)


def write_outputs(
        run_dir: Path,
        *,
        manifest: Mapping[str, Any],
        result: Mapping[str, Any],
        answerable: list[Mapping[str, Any]],
        unanswerable: list[Mapping[str, Any]],
        acl_probes: list[Mapping[str, Any]],
        findings: Iterable[str],
) -> None:
    run_dir.mkdir(parents=True, exist_ok=True)
    _write_json(run_dir / "manifest.json", manifest)
    _write_json(run_dir / "metrics.json", result)
    with (run_dir / "samples.jsonl").open("w", encoding="utf-8") as handle:
        for sample in [*answerable, *unanswerable, *acl_probes]:
            handle.write(json.dumps(sample, ensure_ascii=False) + "\n")
    (run_dir / "report.md").write_text(
        render_markdown(manifest, result, answerable, unanswerable, acl_probes, findings),
        encoding="utf-8",
    )


def load_targets(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def _write_json(path: Path, payload: Mapping[str, Any]) -> None:
    path.write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")


def _meets(value: float | None, target: Any) -> bool | None:
    if value is None or target is None:
        return None
    return value >= float(target)


def _at_most(value: float | None, target: Any) -> bool | None:
    if value is None or target is None:
        return None
    return value <= float(target)


def _status(value: bool | None) -> str:
    if value is None:
        return "n/a"
    return "PASS" if value else "FAIL"


def _fmt(value: Any) -> str:
    if value is None:
        return "-"
    try:
        return f"{float(value):.4f}"
    except (TypeError, ValueError):
        return str(value)


def _fmt_result(value: Any) -> str:
    if value is None:
        return "-"
    return f"{float(value):.2%}"


def _short_hash(value: Any) -> str:
    if not value:
        return "-"
    text = str(value)
    return text[:12]


def _snippet(value: Any, limit: int = 80) -> str:
    text = " ".join(str(value or "").split())
    if len(text) <= limit:
        return text
    return text[:limit] + "…"
