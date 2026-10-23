from __future__ import annotations

import hashlib
import json
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Iterable, Mapping

from .config import CONTEXT_TOKEN_BUDGET

VALID_KINDS = {"answerable", "unanswerable", "acl_probe"}


@dataclass(frozen=True)
class CorpusChunk:
    chunk_id: str
    document_id: str
    title: str
    content: str
    source_type: str
    route: str
    acl_scope: str
    acl_roles: tuple[str, ...]
    acl_user_ids: tuple[str, ...]
    acl_departments: tuple[str, ...]
    raw: Mapping[str, Any]


@dataclass(frozen=True)
class EvalQuestion:
    id: str
    user_input: str
    kind: str
    reference: str
    relevant_chunk_ids: tuple[str, ...]
    must_not_return: tuple[str, ...]
    multihop: bool
    notes: str


@dataclass(frozen=True)
class EvalDataset:
    corpus: Mapping[str, CorpusChunk]
    questions: tuple[EvalQuestion, ...]
    raw: Mapping[str, Any]


def load_json(path: Path) -> dict:
    with path.open(encoding="utf-8") as handle:
        return json.load(handle)


def load_golden_corpus(path: Path) -> dict[str, CorpusChunk]:
    payload = load_json(path)
    corpus: dict[str, CorpusChunk] = {}
    for item in payload.get("corpus", []):
        chunk = CorpusChunk(
            chunk_id=str(item["chunkId"]),
            document_id=str(item.get("documentId", "")),
            title=str(item.get("title", "")),
            content=str(item.get("content", "")),
            source_type=str(item.get("sourceType", "")),
            route=str(item.get("route", "")),
            acl_scope=str(item.get("aclScope", "PUBLIC")).upper(),
            acl_roles=tuple(item.get("aclRoles", ())),
            acl_user_ids=tuple(item.get("aclUserIds", ())),
            acl_departments=tuple(item.get("aclDepartments", ())),
            raw=item,
        )
        if chunk.chunk_id in corpus:
            raise ValueError(f"duplicate golden chunkId: {chunk.chunk_id}")
        corpus[chunk.chunk_id] = chunk
    return corpus


def load_dataset(path: Path, corpus: Mapping[str, CorpusChunk]) -> EvalDataset:
    payload = load_json(path)
    questions: list[EvalQuestion] = []
    for item in payload.get("questions", []):
        questions.append(
            EvalQuestion(
                id=str(item["id"]),
                user_input=str(item["user_input"]).strip(),
                kind=str(item.get("kind", "answerable")),
                reference=str(item.get("reference", "")).strip(),
                relevant_chunk_ids=tuple(item.get("relevant_chunk_ids", ())),
                must_not_return=tuple(item.get("must_not_return", ())),
                multihop=bool(item.get("multihop", False)),
                notes=str(item.get("notes", "")).strip(),
            )
        )
    return EvalDataset(corpus=corpus, questions=tuple(questions), raw=payload)


def validate_dataset(dataset: EvalDataset) -> list[str]:
    errors: list[str] = []
    corpus = dataset.corpus
    public_ids = {chunk_id for chunk_id, chunk in corpus.items() if chunk.acl_scope == "PUBLIC"}

    seen_ids: set[str] = set()
    seen_inputs: dict[str, str] = {}
    covered_public: set[str] = set()

    for question in dataset.questions:
        prefix = f"{question.id}: "
        if question.id in seen_ids:
            errors.append(prefix + "duplicate id")
        seen_ids.add(question.id)
        if question.kind not in VALID_KINDS:
            errors.append(prefix + f"unknown kind {question.kind!r}")
        if not question.user_input:
            errors.append(prefix + "empty user_input")
        if question.user_input in seen_inputs:
            errors.append(prefix + f"duplicate user_input (also used by {seen_inputs[question.user_input]})")
        else:
            seen_inputs[question.user_input] = question.id

        for chunk_id in question.relevant_chunk_ids:
            if chunk_id not in corpus:
                errors.append(prefix + f"unknown relevant chunk {chunk_id}")
        for chunk_id in question.must_not_return:
            if chunk_id not in corpus:
                errors.append(prefix + f"unknown must_not_return chunk {chunk_id}")

        if question.kind == "answerable":
            if not question.reference:
                errors.append(prefix + "answerable question needs a reference answer")
            if not question.relevant_chunk_ids:
                errors.append(prefix + "answerable question needs relevant_chunk_ids")
            non_public = [
                chunk_id
                for chunk_id in question.relevant_chunk_ids
                if chunk_id in corpus and corpus[chunk_id].acl_scope != "PUBLIC"
            ]
            if non_public:
                errors.append(prefix + f"answerable question references non-PUBLIC chunks: {non_public}")
            covered_public.update(question.relevant_chunk_ids)
        elif question.kind == "unanswerable":
            if question.relevant_chunk_ids:
                errors.append(prefix + "unanswerable question must not declare relevant chunks")
            if question.reference:
                errors.append(prefix + "unanswerable question must not declare a reference answer")
        elif question.kind == "acl_probe":
            if not question.must_not_return:
                errors.append(prefix + "acl_probe needs must_not_return")
            if question.relevant_chunk_ids:
                errors.append(prefix + "acl_probe must not declare relevant chunks")

    missing = sorted(public_ids - covered_public)
    if missing:
        errors.append(f"dataset does not cover PUBLIC chunks: {missing}")

    answerable = [question for question in dataset.questions if question.kind == "answerable"]
    if not any(question.multihop for question in answerable):
        errors.append("dataset needs at least one multihop answerable question")

    return errors


def reference_contexts(question: EvalQuestion, corpus: Mapping[str, CorpusChunk]) -> list[str]:
    return [corpus[chunk_id].content for chunk_id in question.relevant_chunk_ids]


def estimate_tokens(text: str) -> int:
    """Mirror ContextBuilder.estimateTokens: ASCII runs count as one token each."""
    tokens = 0
    index = 0
    while index < len(text):
        character = text[index]
        if character.isspace():
            index += 1
            continue
        tokens += 1
        if character.isascii() and character.isalnum():
            index += 1
            while index < len(text) and text[index].isascii() and text[index].isalnum():
                index += 1
        else:
            index += 1
    return tokens


def context_prompt_text(results: Iterable[Mapping[str, Any]]) -> str:
    entries = []
    for index, result in enumerate(results, start=1):
        metadata = result.get("metadata") or {}
        source = str(metadata.get("source") or "").strip()
        if not source:
            source_table = str(result.get("sourceTable") or "")
            source_id = str(result.get("sourceId") or "")
            source = f"{source_table}:{source_id}" if source_table and source_id else source_table or source_id
        entries.append(
            f"[{index}]\n"
            f"title: {result.get('title') or ''}\n"
            f"source: {source}\n"
            f"score: {float(result.get('finalScore') or 0.0):.4f}\n"
            f"content: {' '.join(str(result.get('content') or '').split())}"
        )
    return "\n\n".join(entries)


def context_within_budget(results: Iterable[Mapping[str, Any]]) -> bool:
    return estimate_tokens(context_prompt_text(results)) <= CONTEXT_TOKEN_BUDGET


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def corpus_hash(corpus: Mapping[str, CorpusChunk]) -> str:
    canonical = json.dumps(
        [corpus[chunk_id].raw for chunk_id in sorted(corpus)],
        ensure_ascii=False,
        sort_keys=True,
        separators=(",", ":"),
    )
    return hashlib.sha256(canonical.encode("utf-8")).hexdigest()
