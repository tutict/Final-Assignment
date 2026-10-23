from __future__ import annotations

from ragas_eval.config import DATASET_PATH, GOLDEN_SET_PATH
from ragas_eval.dataset import (
    CorpusChunk,
    EvalDataset,
    EvalQuestion,
    context_prompt_text,
    context_within_budget,
    estimate_tokens,
    load_dataset,
    load_golden_corpus,
    reference_contexts,
    validate_dataset,
)


def repository_dataset() -> EvalDataset:
    corpus = load_golden_corpus(GOLDEN_SET_PATH)
    return load_dataset(DATASET_PATH, corpus)


def test_repository_dataset_is_valid() -> None:
    assert validate_dataset(repository_dataset()) == []


def test_kind_counts_and_public_coverage() -> None:
    dataset = repository_dataset()
    kinds = {}
    for question in dataset.questions:
        kinds[question.kind] = kinds.get(question.kind, 0) + 1
    assert kinds == {"answerable": 30, "unanswerable": 3, "acl_probe": 3}

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
    assert public_ids <= covered

    multihop = [q for q in dataset.questions if q.kind == "answerable" and q.multihop]
    assert len(multihop) >= 4


def test_answerable_questions_only_use_public_chunks() -> None:
    dataset = repository_dataset()
    for question in dataset.questions:
        if question.kind != "answerable":
            continue
        assert question.reference
        assert question.relevant_chunk_ids
        for chunk_id in question.relevant_chunk_ids:
            assert dataset.corpus[chunk_id].acl_scope == "PUBLIC"


def test_reference_contexts_follow_declared_chunk_order() -> None:
    dataset = repository_dataset()
    question = next(q for q in dataset.questions if q.kind == "answerable")
    contexts = reference_contexts(question, dataset.corpus)
    assert contexts == [dataset.corpus[chunk_id].content for chunk_id in question.relevant_chunk_ids]


def test_estimate_tokens_matches_java_semantics() -> None:
    assert estimate_tokens("") == 0
    assert estimate_tokens("   ") == 0
    assert estimate_tokens("abc 中文") == 3
    assert estimate_tokens("[1]\ntitle: demo") == 6


def test_context_budget_uses_prompt_layout() -> None:
    small = [{"sourceTable": "manual", "sourceId": "c1", "title": "标题", "content": "内容", "finalScore": 1.0}]
    assert context_within_budget(small)
    assert "[1]" in context_prompt_text(small)

    oversized = [{"sourceTable": "manual", "sourceId": "c1", "title": "标题", "content": "字" * 2000}]
    assert not context_within_budget(oversized)


def test_validate_reports_unknown_chunks_and_bad_kinds() -> None:
    corpus = {"c1": chunk("c1")}
    dataset = EvalDataset(
        corpus=corpus,
        questions=(
            EvalQuestion("a1", "问题", "answerable", "答案", ("missing",), (), False, ""),
            EvalQuestion("u1", "问题二", "unanswerable", "不应有答案", (), (), False, ""),
            EvalQuestion("p1", "问题三", "acl_probe", "", (), (), False, ""),
            EvalQuestion("x1", "问题四", "mystery", "", (), (), False, ""),
        ),
        raw={},
    )
    errors = validate_dataset(dataset)
    assert any("unknown relevant chunk missing" in error for error in errors)
    assert any("unanswerable question must not declare a reference answer" in error for error in errors)
    assert any("acl_probe needs must_not_return" in error for error in errors)
    assert any("unknown kind" in error for error in errors)
    assert any("does not cover PUBLIC chunks" in error for error in errors)


def test_validate_rejects_duplicate_ids_and_inputs() -> None:
    corpus = {"c1": chunk("c1")}
    dataset = EvalDataset(
        corpus=corpus,
        questions=(
            EvalQuestion("a1", "同一个问题", "answerable", "答案", ("c1",), (), False, ""),
            EvalQuestion("a1", "同一个问题", "answerable", "答案", ("c1",), (), False, ""),
        ),
        raw={},
    )
    errors = validate_dataset(dataset)
    assert any("duplicate id" in error for error in errors)
    assert any("duplicate user_input" in error for error in errors)


def chunk(chunk_id: str, scope: str = "PUBLIC") -> CorpusChunk:
    return CorpusChunk(
        chunk_id=chunk_id,
        document_id="doc-1",
        title="标题",
        content="内容",
        source_type="BUSINESS",
        route="/x",
        acl_scope=scope,
        acl_roles=(),
        acl_user_ids=(),
        acl_departments=(),
        raw={"chunkId": chunk_id},
    )
