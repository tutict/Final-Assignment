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
    metrics = [
        Faithfulness(),
        ResponseRelevancy(),
        LLMContextPrecisionWithReference(),
        LLMContextRecall(),
        AnswerCorrectness(),
    ]
    run_config = RunConfig(max_workers=max_workers, timeout=timeout, max_retries=max_retries)

    try:
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
        result = evaluate(
            dataset=dataset,
            metrics=metrics,
            llm=judge,
            embeddings=embeddings,
            run_config=run_config,
        )
        frame = result.to_pandas()
    except Exception as error:  # RAGAS raises heterogeneous parser/validation errors
        raise MetricsError(f"RAGAS evaluation failed: {error}") from error

    rows: list[dict[str, float | None]] = []
    for record in frame.to_dict("records"):
        row: dict[str, float | None] = {}
        for column, value in record.items():
            key = canonical_metric_key(str(column))
            if key is not None and key not in row:
                row[key] = as_float(value)
        rows.append({key: row.get(key) for key in METRIC_KEYS})

    if len(rows) != len(records):
        raise MetricsError(f"RAGAS returned {len(rows)} rows for {len(records)} inputs")
    return rows


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
