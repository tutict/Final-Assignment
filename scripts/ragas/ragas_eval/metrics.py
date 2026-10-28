from __future__ import annotations

import math
from typing import Any, Iterable

from .config import METRIC_KEYS, Settings


class MetricsError(RuntimeError):
    pass


def compute_metrics(
        records: list[dict[str, Any]],
        settings: Settings,
        *,
        max_workers: int = 2,
        timeout: int = 300,
        max_retries: int = 2,
) -> list[dict[str, float | None]]:
    if not records:
        return []
    try:
        from datasets import Dataset
        from langchain_ollama import ChatOllama, OllamaEmbeddings
        from ragas import EvaluationDataset, RunConfig, evaluate
        from ragas.embeddings import LangchainEmbeddingsWrapper
        from ragas.llms import LangchainLLMWrapper
        from ragas.metrics import (
            AnswerCorrectness,
            Faithfulness,
            LLMContextPrecisionWithReference,
            LLMContextRecall,
            ResponseRelevancy,
        )
    except ImportError as error:
        raise MetricsError(
            "RAGAS dependencies are missing; run `uv sync` inside scripts/ragas"
        ) from error

    judge = LangchainLLMWrapper(
        ChatOllama(
            model=settings.judge_model,
            base_url=settings.ollama_url,
            temperature=0,
            num_ctx=8192,
            # Verdicts are short; a runaway generation would otherwise stall the whole run.
            num_predict=512,
            client_kwargs={"trust_env": False},
        )
    )
    # AnswerCorrectness first asks the judge to decompose both answers into statements, so it
    # needs more output headroom than a yes/no verdict. It also runs alone: under concurrent
    # load a malformed decomposition silently collapses the factual score to zero.
    correctness_judge = LangchainLLMWrapper(
        ChatOllama(
            model=settings.judge_model,
            base_url=settings.ollama_url,
            temperature=0,
            num_ctx=8192,
            num_predict=2048,
            client_kwargs={"trust_env": False},
        )
    )
    embeddings = LangchainEmbeddingsWrapper(
        OllamaEmbeddings(
            model=settings.judge_embedding_model,
            base_url=settings.ollama_url,
            client_kwargs={"trust_env": False},
        )
    )
    primary_metrics = [
        Faithfulness(),
        ResponseRelevancy(),
        LLMContextPrecisionWithReference(),
        LLMContextRecall(),
    ]
    run_config = RunConfig(max_workers=max_workers, timeout=timeout, max_retries=max_retries)

    try:
        primary_rows = _evaluate_rows(
            records, primary_metrics, judge, embeddings, run_config, "primary metrics"
        )
        correctness_rows = _evaluate_rows(
            records,
            [AnswerCorrectness()],
            correctness_judge,
            embeddings,
            RunConfig(max_workers=1, timeout=max(timeout, 600), max_retries=max_retries),
            "answer correctness",
        )
        correctness_rows = _retry_missing(
            records, correctness_rows, correctness_judge, embeddings, max_retries
        )
    except MetricsError:
        raise
    except Exception as error:  # RAGAS raises heterogeneous parser/validation errors
        raise MetricsError(f"RAGAS evaluation failed: {error}") from error

    if len(primary_rows) != len(records) or len(correctness_rows) != len(records):
        raise MetricsError(
            f"RAGAS returned {len(primary_rows)}/{len(correctness_rows)} rows for {len(records)} inputs"
        )

    rows: list[dict[str, float | None]] = []
    for index in range(len(records)):
        merged: dict[str, float | None] = {}
        for source in (primary_rows[index], correctness_rows[index]):
            for column, value in source.items():
                key = canonical_metric_key(str(column))
                if key is not None and key not in merged:
                    merged[key] = as_float(value)
        rows.append({key: merged.get(key) for key in METRIC_KEYS})
    return rows


def _evaluate_rows(records, metrics, judge, embeddings, run_config, label: str):
    from datasets import Dataset
    from ragas import EvaluationDataset, evaluate

    dataset = EvaluationDataset.from_hf_dataset(
        Dataset.from_list(
            [
                {
                    "user_input": record["user_input"],
                    "response": record["response"],
                    "retrieved_contexts": record["retrieved_contexts"],
                    "reference": record["reference"],
                }
                for record in records
            ]
        )
    )
    try:
        result = evaluate(
            dataset=dataset,
            metrics=metrics,
            llm=judge,
            embeddings=embeddings,
            run_config=run_config,
        )
    except Exception as error:  # RAGAS raises heterogeneous parser/validation errors
        raise MetricsError(f"RAGAS {label} evaluation failed: {error}") from error
    return result.to_pandas().to_dict("records")


def _retry_missing(records, correctness_rows, judge, embeddings, max_retries: int):
    from ragas.metrics import AnswerCorrectness

    missing = [
        index
        for index, row in enumerate(correctness_rows)
        if as_float(row.get("answer_correctness")) is None
    ]
    for _ in range(max(0, max_retries)):
        if not missing:
            break
        retry_rows = _evaluate_rows(
            [records[index] for index in missing],
            [AnswerCorrectness()],
            judge,
            embeddings,
            RunConfig(max_workers=1, timeout=600, max_retries=max_retries),
            "answer correctness retry",
        )
        for index, row in zip(missing, retry_rows, strict=True):
            if as_float(row.get("answer_correctness")) is not None:
                correctness_rows[index] = row
        missing = [
            index
            for index, row in enumerate(correctness_rows)
            if as_float(row.get("answer_correctness")) is None
        ]
    return correctness_rows


def canonical_metric_key(column: str) -> str | None:
    normalized = column.lower()
    if normalized in {
        "user_input",
        "response",
        "retrieved_contexts",
        "reference",
        "reference_contexts",
    }:
        return None
    if "faithful" in normalized:
        return "faithfulness"
    if "relevan" in normalized:
        return "response_relevancy"
    if "precision" in normalized:
        return "context_precision"
    if "recall" in normalized:
        return "context_recall"
    if "correct" in normalized:
        return "answer_correctness"
    return None


def as_float(value: Any) -> float | None:
    if value is None:
        return None
    try:
        number = float(value)
    except (TypeError, ValueError):
        return None
    if math.isnan(number) or math.isinf(number):
        return None
    return number


def mean(values: Iterable[float | None]) -> float | None:
    present = [value for value in values if value is not None]
    if not present:
        return None
    return sum(present) / len(present)
