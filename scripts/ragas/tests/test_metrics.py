from ragas_eval.metrics import as_float, canonical_metric_key, mean


def test_canonical_metric_key_maps_ragas_columns() -> None:
    assert canonical_metric_key("faithfulness") == "faithfulness"
    assert canonical_metric_key("response_relevancy") == "response_relevancy"
    assert canonical_metric_key("llm_context_precision_with_reference") == "context_precision"
    assert canonical_metric_key("context_recall") == "context_recall"
    assert canonical_metric_key("answer_correctness") == "answer_correctness"


def test_canonical_metric_key_ignores_dataset_columns() -> None:
    for column in ("user_input", "response", "retrieved_contexts", "reference", "reference_contexts"):
        assert canonical_metric_key(column) is None


def test_as_float_rejects_missing_and_non_finite_scores() -> None:
    assert as_float(None) is None
    assert as_float("not-a-number") is None
    assert as_float(float("nan")) is None
    assert as_float(float("inf")) is None
    assert as_float("0.75") == 0.75


def test_mean_ignores_missing_scores() -> None:
    assert mean([0.5, None, 1.0]) == 0.75
    assert mean([None, None]) is None
