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

* retrieved context content in `ContextBuilder`, and
* the user message before prompt assembly in `ChatPipeline`.

### 3.2 Citation enforcement

`AnswerGroundingPolicy` (`ai/guardrail`) enforces "no citation, no answer" for turns
that actually rely on retrieval:

* no sources retrieved -> safe fallback (`no_sources`);
* sources retrieved but the answer cites none (no in-range `[n]`, source id, document id
  or title) -> safe fallback (`missing_citation`).

`ChatPipeline` buffers the model output only for retrieval-grounded turns, so an uncited
answer can be replaced before it reaches the user; non-retrieval turns keep streaming
unchanged. Before refusing, a pure-chat turn with retrieved sources gets **one citation
repair retry**: the same request is re-issued with an extra instruction that every
factual sentence must carry an `[n]` marker. The retry keeps the first attempt's
`messageId`, and only a second uncited answer is replaced with the refusal. The agent
path is excluded because replaying it would re-run tools and side effects.

Queue notifications (`QUEUE`) and keep-alives are forwarded immediately and are never
buffered as answer text, so a queue notice cannot exempt an answer from citation
checking.

Scope and safety of the rewrite:

* Only **plain-text answers** (TOKEN / DONE) are subject to enforcement. Structured
  control events (`TOOL`, `DRAFT`, `RESULT`, `ACTION`) and infrastructure messages
  (bulkhead/fallback, `ERROR`, any event carrying `isFallback`) pass through untouched,
  so a refusal can never swallow a draft card, a navigation action or rewrite an
  "AI unavailable" fallback.
* Keep-alives are forwarded immediately while the answer is buffered, so the SSE
  connection stays alive during the check.
* Citation matching ignores non-distinctive identifiers (bare row ids such as `12` or
  `7`), which would otherwise match almost any answer and let an uncited answer pass.
  Han titles count from two characters; Latin identifiers must contain a letter and be
  at least four characters (e.g. `doc-1`).

Residual gap: retrieved context is rendered as citation index plus content only, so
document titles, source ids and scores are no longer available to the model to echo.
Citation matching still accepts a distinctive source id or title if a model emits one
spontaneously, but those identifiers are no longer part of the prompt. The agent path
passes the caller's own message through as a user turn; that is deliberate, since
sanitizing it would break intent routing.

The injection filter is recall-oriented by design, so it has a bounded false-positive
rate on user input (for example a question phrased as "how do I ignore the previous
error prompt" can have that span neutralized). Only the matched span is replaced, the
rest of the message is preserved, and the guard is deterministic and unit-tested
(including a long-input scan bound).

Toggle: `ai.guardrail.citation-enforcement.enabled` (env `AI_GUARDRAIL_CITATION_ENFORCEMENT`,
default `true`).

## 4. RAGAS answer-quality baseline (on demand)

Section 1 checks retrieval ranking offline. `scripts/ragas` complements it by scoring the
**answers** produced by the real HTTP pipeline: retrieval comes from `POST /api/rag/query`
and answers from `POST /api/ai/chat/stream` (same identity, prompt, guardrails and Ollama
models as the product). It is not part of CI because it requires ES, MySQL, Redis and local
Ollama models.

### Dataset

* 30 answerable Chinese questions covering all 22 PUBLIC golden chunks, 4 of them multihop.
* 3 unanswerable questions (abstention / hallucination probes).
* 3 ACL probes (USER -> admin log, wrong user -> "my offense record", no department -> department SOP).
* Each seeded chunk uses the golden `chunkId` as `sourceId`, so retrieval results align with
  the dataset exactly. `golden-set.json` is read-only.

### Running

The server must run in pure-RAG mode; otherwise the agent tool router answers from the
database instead of the retrieved context:

```bash
cd finalAssignmentBackend
AI_AGENT_ENABLED=false RAG_RETRIEVAL_ENABLED=true \
RAG_INDEX_NAME=rag_chunk_ragas_v1 RAG_INDEX_ALIAS=rag_chunk_ragas_current \
mvn spring-boot:run

cd scripts/ragas
uv sync --frozen
uv run ragas-eval validate
uv run ragas-eval preflight
uv run ragas-eval seed
uv run ragas-eval run --top-k 5 --run-id baseline-20261023
```

Readiness is proven in two steps: every chunk embedding task must be `SUCCEEDED`, then each
seeded `source_id` must be term-visible on the configured alias. The check deliberately does
not assume semantic ranking quality, because ranking is what the evaluation measures.

Models: product answer `llama3.2`, product embedding `nomic-embed-text`, judge `qwen2.5:7b`,
evaluation embedding `bge-m3` (evaluation side only). `RAGAS_OLLAMA_URL` must point at the
instance that actually holds the judge and evaluation embedding. The product path sends
`temperature=0.2` by default (`OLLAMA_TEMPERATURE`).

### Metrics and baseline (2026-10-23)

RAGAS 0.4.3: Faithfulness, Response Relevancy, LLM Context Precision (with reference),
LLM Context Recall, Answer Correctness. Hard failures are ACL leakage, context drift,
provider errors, scoring failures and preflight failures; score thresholds in
`scripts/ragas/targets.json` are advisory until a baseline is reviewed (`--enforce` turns
them into failures).

| metric | baseline | target |
| --- | ---: | ---: |
| Faithfulness | 0.8017 | 0.75 |
| Response Relevancy | 0.7918 | 0.75 |
| Context Precision | 0.8511 | 0.60 |
| Context Recall | 0.9667 | 0.85 |
| Answer Correctness | 0.7601 | 0.55 |
| Citation compliance | 0.9667 | 0.90 |
| Fallback rate | 0.0000 | <= 0.10 |
| Unanswerable abstention | 0.3333 | 0.80 (advisory) |

30/30 answerable samples were scored, with 0 ACL leaks, 0 context drift and 0 provider
errors. Retrieval hit@5 was 29/30 and relevant-chunk recall 93.3%. Known gaps: weak
abstention on out-of-corpus questions, internal context labels (`retrieved_context`) leaking
into 6/30 answers, and a retrieval-depth issue where a BM25 top-1 chunk can miss the final
top-5 at `topK=5` because it is absent from the vector candidate list.

Full report and machine-readable snapshot:
`docs/ai/ragas/baseline-2026-10-23.md` and `.json`. Raw artifacts stay in
`artifacts/ragas/<run-id>/` (gitignored).

### Latest results (2026-10-28)

Final round `improvement4-20261028`, same dataset and models, topK=5:

| metric | value | target |
| --- | ---: | ---: |
| Faithfulness | 0.9889 | 0.75 |
| Response Relevancy | 0.8889 | 0.75 |
| Context Precision | 0.9609 | 0.60 |
| Context Recall | 0.9833 | 0.85 |
| Answer Correctness | 0.7781 | 0.55 |
| Citation compliance | 1.0000 | 0.90 |
| Fallback rate | 0.0000 | <= 0.10 |
| Unanswerable abstention | 0.0000 | 0.80 (advisory) |

30/30 answerable samples scored, 0 ACL leaks, 0 context drift, 0 provider errors. Context
Precision is averaged over 29 samples: the judge output for a30 failed to parse. Retrieval
regressed nothing: hit@5 is 30/30 with recall 0.9833, MRR 0.9833, nDCG@5 0.9769; the
production default `topK=10` scores hit 30/30, recall 1.0000, MRR 0.9833, nDCG 0.9898.

What changed relative to the baseline: retrieved context now exposes only the citation
index and content (no titles, source ids or scores), the prompt has five citation rules
with a repair variant, Ollama runs at `temperature=0.2`, and an uncited answer gets one
citation-repair retry before the guardrail refuses. Citation compliance moved 0.8333
(25/30 scored) -> 0.9000 (27/30) -> 1.0000 (30/30) across the three 2026-10-28 runs.
On the 23 samples scored in every run, Faithfulness is 0.8087 -> 0.9855 and Context
Precision 0.8551 -> 0.9485; Answer Correctness remains noisy (0.7313 -> 0.7568).

Two earlier numbers need correction:

* The first-round AC drop (0.7601 -> 0.6479) was a harness artifact: the judge was
  capped at 512 tokens, which truncated statement decomposition. Rescoring the same
  answers with 2048 tokens gives 0.7579 (baseline) and 0.7710 (first round). AC now runs
  isolated with `num_predict=2048`, `max_workers=1` and retries missing rows.
* The historical "1/3" unanswerable abstention was a citation-guardrail refusal
  (`u01` returned `UNCITED_ANSWER`), not model abstention. True abstention is 0/3 in
  every run and remains the main quality gap.

Full report: `docs/ai/ragas/improvement-2026-10-28.md`.

### Limitations

* Only pure-RAG mode is covered; the default agent mode routes knowledge questions to tools.
* Absolute scores depend on the judge model; individual zero scores should be checked against
  the answer and contexts before being treated as defects.
* The suite needs ES/MySQL/Redis + Ollama and stays outside CI; CI keeps the deterministic
  retrieval gate from section 1.
