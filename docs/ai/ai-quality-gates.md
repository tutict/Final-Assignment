# AI Quality Gates (RAG eval + guardrails)

This document describes the automated quality gates that protect the AI/RAG surface of
`finalAssignmentBackend`. They run as part of `mvn test` and therefore in CI.

## 1. RAG retrieval evaluation

`RagRetrievalQualityTest` runs a deterministic, offline retrieval evaluation against a
versioned golden set, so retrieval quality changes are caught in CI instead of in
production.

* **Golden set:** `src/test/resources/rag-eval/golden-set.json`
  * 30 corpus chunks spanning PUBLIC / ROLE / USER / DEPARTMENT ACL scopes.
  * 64 queries: 60 quality queries with expected relevant chunks + 4 ACL-negative
    queries that must **not** return restricted chunks.
* **Harness:** `ai/rag/retrieval/*`
  * `InMemoryRagSearchBackend` implements real BM25 (k1=1.2, b=0.75) plus cosine vector
    search and reuses the production `AclFilterService` for access control.
  * `HashingBagOfWordsEmbedding` is a deterministic hashing bag-of-words embedding, so
    the eval needs no model server and produces stable numbers.
  * `RagRetrievalMetrics` computes recall@k, precision@k, MRR and nDCG@k.
* **Asserted thresholds** (fail the build if regressed):

  | metric        | threshold |
  |---------------|-----------|
  | recall@5      | >= 0.95   |
  | recall@3      | >= 0.85   |
  | MRR           | >= 0.85   |
  | nDCG@5        | >= 0.85   |
  | precision@5   | >= 0.15   |

* **Current baseline** (printed as `[rag-eval] ...`):
  `queries=60 recall@1=0.808 recall@3=0.975 recall@5=1.000 precision@5=0.227 MRR=0.926 nDCG@5=0.944`
* The suite also includes an ablation (hybrid vs. BM25-only) and an ACL no-leak test.

Run just this suite:

```bash
mvn -pl finalAssignmentBackend test -Dtest=RagRetrievalQualityTest
```

## 2. Full test coverage in `mvn test`

The Surefire configuration previously included only `**/*IntegrationTest.java` and
`**/*RegressionTest.java`, silently skipping ~49 test classes. It now includes
`**/*Test.java`, so every test class runs in CI.

## 3. Guardrails

### 3.1 Prompt-injection filter

`PromptInjectionGuard` (`ai/guardrail`) scans untrusted text for the most common
instruction-override patterns (English + Chinese): instruction override, system-prompt
extraction, role hijack and jailbreak. Matched spans are replaced with the neutralized
marker `[已过滤的指令性内容]`, so the model sees data rather than instructions.

It is applied to:

* retrieved context (title + content) in `ContextBuilder`, and
* the user message before prompt assembly in `ChatPipeline`.

### 3.2 Citation enforcement

`AnswerGroundingPolicy` (`ai/guardrail`) enforces "no citation, no answer" for turns
that actually rely on retrieval:

* no sources retrieved -> safe fallback (`no_sources`);
* sources retrieved but the answer cites none (no in-range `[n]`, source id, document id
  or title) -> safe fallback (`missing_citation`).

`ChatPipeline` buffers the model output only for retrieval-grounded turns, so an uncited
answer can be replaced before it reaches the user; non-retrieval turns keep streaming
unchanged.

Scope and safety of the rewrite:

* Only **plain-text answers** (TOKEN / DONE) are subject to enforcement. Structured
  control events (`TOOL`, `DRAFT`, `RESULT`, `ACTION`, `QUEUE`) and infrastructure
  messages (bulkhead/fallback, `ERROR`, any event carrying `isFallback`) pass through
  untouched, so a refusal can never swallow a draft card, a navigation action or rewrite
  an "AI unavailable" fallback.
* Keep-alives are forwarded immediately while the answer is buffered, so the SSE
  connection stays alive during the check.
* Citation matching ignores non-distinctive identifiers (bare row ids such as `12` or
  `7`), which would otherwise match almost any answer and let an uncited answer pass.
  Han titles count from two characters; Latin identifiers must contain a letter and be
  at least four characters (e.g. `doc-1`).

Residual gap: retrieved `source` strings are rendered verbatim (they are technical
identifiers such as `docs:7`), and the agent path passes the caller's own message
through as a user turn. Both are deliberate: sanitizing them would break citation
matching and intent routing respectively.

Toggle: `ai.guardrail.citation-enforcement.enabled` (env `AI_GUARDRAIL_CITATION_ENFORCEMENT`,
default `true`).
