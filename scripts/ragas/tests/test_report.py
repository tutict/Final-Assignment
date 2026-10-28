from __future__ import annotations

import json

from ragas_eval.config import METRIC_KEYS, TARGETS_PATH
from ragas_eval.report import aggregate, load_targets, render_markdown, write_outputs

TARGETS = {
    "faithfulness": 0.75,
    "response_relevancy": 0.75,
    "context_precision": 0.60,
    "context_recall": 0.85,
    "answer_correctness": 0.55,
    "citation_compliance": 0.90,
    "max_fallback_rate": 0.10,
    "max_acl_leakage": 0,
    "min_unanswerable_abstention": 0.80,
    "min_scored_coverage": 0.90,
    "enforce": False,
}


def metrics(value: float) -> dict[str, float]:
    return {key: value for key in METRIC_KEYS}


def answerable(sample_id: str, **overrides) -> dict:
    sample = {
        "id": sample_id,
        "kind": "answerable",
        "user_input": f"问题 {sample_id}",
        "answer": "回答[1]",
        "multihop": False,
        "scored": True,
        "metrics": metrics(0.8),
        "error": None,
        "citation_compliant": True,
        "fallback": False,
        "exclusion_reason": None,
        "guardrail_refusal": None,
        "context_drift": False,
        "retrieved_chunk_ids": ["c1"],
    }
    sample.update(overrides)
    return sample


def unanswerable(sample_id: str = "u1", **overrides) -> dict:
    sample = {
        "id": sample_id,
        "kind": "unanswerable",
        "user_input": "无法回答的问题",
        "answer": "知识库资料不足。",
        "abstained": True,
        "retrieved_chunk_ids": [],
    }
    sample.update(overrides)
    return sample


def acl_probe(sample_id: str = "p1", **overrides) -> dict:
    sample = {
        "id": sample_id,
        "kind": "acl_probe",
        "user_input": "越权查询",
        "must_not_return": ["c-admin"],
        "retrieved_chunk_ids": ["c-public"],
        "leaked": False,
        "error": None,
    }
    sample.update(overrides)
    return sample


def manifest() -> dict:
    return {
        "run_id": "run-1",
        "timestamp": "2026-10-23T00:00:00+00:00",
        "git_commit": "abc123",
        "base_url": "http://localhost:9080",
        "answer_model": "llama3.2",
        "judge_model": "qwen2.5:7b",
        "judge_embedding_model": "bge-m3",
        "top_k": 5,
        "dataset_hash": "d" * 64,
        "corpus_hash": "c" * 64,
    }


def test_aggregate_uses_only_scored_samples_for_means() -> None:
    samples = [
        answerable("a1", metrics=metrics(1.0)),
        answerable("a2", metrics=metrics(0.5), multihop=True),
        answerable(
            "a3",
            scored=False,
            metrics={key: None for key in METRIC_KEYS},
            exclusion_reason="empty_context",
            fallback=True,
            citation_compliant=False,
        ),
    ]
    result = aggregate(samples, [unanswerable()], [acl_probe()], TARGETS)

    assert result["answerable_samples"] == 3
    assert result["scored_samples"] == 2
    assert result["scored_coverage"] == 2 / 3
    assert result["metrics"]["faithfulness"]["mean"] == 0.75
    assert result["metrics"]["faithfulness"]["meets_target"] is True
    assert result["exclusion_reasons"] == {"empty_context": 1}
    assert result["fallback_rate"] == 1 / 3
    assert result["citation_compliance"] == 2 / 3
    assert result["multihop"]["metrics"]["faithfulness"] == 0.5
    assert result["unanswerable"]["abstention_rate"] == 1.0
    assert result["acl"]["leaked"] == 0


def test_hard_failures_cover_acl_drift_and_provider_errors() -> None:
    samples = [
        answerable("a1", context_drift=True),
        answerable("a2", error="chat failed: timeout"),
    ]
    result = aggregate(samples, [], [acl_probe(leaked=True, retrieved_chunk_ids=["c-admin"])], TARGETS)
    assert any("ACL leakage" in failure for failure in result["hard_failures"])
    assert any("context drift" in failure for failure in result["hard_failures"])
    assert any("provider errors" in failure for failure in result["hard_failures"])
    assert not any("below target" in failure for failure in result["hard_failures"])


def test_enforce_turns_score_gaps_into_failures() -> None:
    targets = dict(TARGETS, enforce=True)
    samples = [
        answerable("a1", metrics=metrics(0.1), citation_compliant=False),
        answerable(
            "a2",
            scored=False,
            metrics={key: None for key in METRIC_KEYS},
            exclusion_reason="empty_context",
        ),
    ]
    result = aggregate(samples, [unanswerable(abstained=False)], [acl_probe()], targets)

    failures = result["hard_failures"]
    assert any("faithfulness=0.1000 below target" in failure for failure in failures)
    assert any("citation compliance" in failure for failure in failures)
    assert any("scored coverage" in failure for failure in failures)
    assert any("unanswerable abstention" in failure for failure in failures)


def test_metrics_error_is_a_hard_failure() -> None:
    result = aggregate(
        [answerable("a1", scored=False, metrics={key: None for key in METRIC_KEYS}, exclusion_reason="metrics_error")],
        [],
        [],
        TARGETS,
        metrics_error="judge returned invalid JSON",
    )
    assert result["metrics_error"] == "judge returned invalid JSON"
    assert any("RAGAS scoring failed" in failure for failure in result["hard_failures"])


def test_render_markdown_includes_slices_and_errors() -> None:
    result = aggregate(
        [answerable("a1")],
        [unanswerable()],
        [acl_probe(leaked=True, retrieved_chunk_ids=["c-admin"])],
        TARGETS,
        metrics_error="judge timeout",
    )
    markdown = render_markdown(
        manifest(),
        result,
        [answerable("a1")],
        [unanswerable()],
        [acl_probe(leaked=True, retrieved_chunk_ids=["c-admin"])],
        ["附带发现一"],
    )
    assert "# RAGAS 答案质量基线报告" in markdown
    assert "## 总表" in markdown
    assert "## ACL 探针" in markdown
    assert "LEAK" in markdown
    assert "RAGAS 评分失败" in markdown
    assert "附带发现一" in markdown
    assert "评估目标" not in markdown


def test_render_markdown_labels_evaluation_target() -> None:
    samples = [answerable("a1")]
    probes = [acl_probe()]
    unanswered = [unanswerable()]
    result = aggregate(samples, unanswered, probes, TARGETS)
    markdown = render_markdown(
        dict(manifest(), target="Spring Cloud 后端"),
        result,
        samples,
        unanswered,
        probes,
        [],
    )
    assert "| 评估目标 | Spring Cloud 后端 |" in markdown


def test_write_outputs_creates_all_artifacts(tmp_path) -> None:
    samples = [answerable("a1")]
    probes = [acl_probe()]
    unanswered = [unanswerable()]
    result = aggregate(samples, unanswered, probes, TARGETS)
    write_outputs(
        tmp_path,
        manifest=manifest(),
        result=result,
        answerable=samples,
        unanswerable=unanswered,
        acl_probes=probes,
        findings=["发现"],
    )

    for filename in ("manifest.json", "metrics.json", "samples.jsonl", "report.md"):
        assert (tmp_path / filename).exists()
    assert json.loads((tmp_path / "metrics.json").read_text(encoding="utf-8"))["answerable_samples"] == 1
    lines = (tmp_path / "samples.jsonl").read_text(encoding="utf-8").splitlines()
    assert len(lines) == 3


def test_repository_targets_are_advisory_first() -> None:
    targets = load_targets(TARGETS_PATH)
    assert targets["enforce"] is False
    assert set(METRIC_KEYS) <= set(targets)
