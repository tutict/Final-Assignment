# Module Governance Matrix

Status: accepted

This matrix classifies backend modules by long-term governance state. It is intended to stop accidental rollout expansion after the Appeal, Offense, Payment, and convergence work.

## Governance states

| State | Meaning |
|---|---|
| enforced | Existing governance may block unsafe mutations in narrow, proven paths. |
| partial enforced | Some sources or semantic paths are enforced; other paths remain compatibility or shadow. |
| hybrid | Domain uses explicit governance seams, but not all behavior is rollout controlled. |
| shadow | Domain emits observable decisions without changing runtime behavior. |
| retrieval-only | Only read projection, retrieval-safe field, or query repair rules are allowed. |
| avoid | Do not add mutation governance rollout. |

## Domain classification

| Domain | Governance State | Why |
|---|---|---|
| Appeal | hybrid | Appeal has stable domain seams for application service orchestration, event intent, caller intent, workflow decisions, idempotency, cache policy, after-commit Kafka/ES, and read projections. It should remain domain-owned, not converted into a platform template. |
| Offense | partial enforced | Offense has enough evidence for selected enforcement: stale Kafka `FULL_UPDATE`, workflow stale protection, guarded merge, no-op suppression, and structured rollout visibility. Controller compatibility and shadow logs remain part of the migration boundary. |
| PaymentRecord | shadow | Payment has financial side effects and sensitive fields. Current value is semantic audit, side-effect topology, no-op visibility, read repair visibility, and structured shadow logs. It is not ready for stale rejection or guarded merge. |
| Workflow state machines | domain-specific enforced | Workflow protection is valid only when the domain owns explicit transition semantics. Appeal and Offense have domain rules; Payment workflow is shadow-observed. No generic workflow governance should be introduced. |
| SysRequestHistory | avoid | This module is an idempotency and audit ledger. Governance depends on it as evidence, so mutation rollout here would risk corrupting the evidence layer. Keep duplicate handling and ledger updates explicit. |
| Appeal read/projection/query | retrieval-only | Read governance is allowed for projection, DB fallback, search backfill, and retrieval-safe fields. It must not inherit mutation enforcement rules. |
| Offense query repair | retrieval-only | Query repair can be logged and coordinated, but it should not drive mutation rollout decisions. |
| Payment query repair | shadow | Read repair is observable only. It should not become financial write enforcement. |
| IAM and security-sensitive modules | avoid | Access control and authentication rules require specialized security design. Do not apply governance rollout modes or semantic mutation enforcement. |
| AI/RAG/prompt modules | avoid | These are retrieval and generation pipelines, not legacy entity mutation flows. Do not add mutation governance, rollout modes, or enforcement. |
| SSE and realtime streaming | avoid | Streams are delivery infrastructure. Govern producer side effects locally if needed, but do not add SSE governance rollout. |
| Kafka topic/schema ownership | avoid | Topics and payloads are external contracts. Governance must not change topic names, schemas, or consumer compatibility. |
| Elasticsearch mapping/index structure | avoid | Governance may observe index writes and read repair, but must not modify mapping or index structure as part of rollout. |
| Generic CRUD modules without incident evidence | avoid | Do not add governance just because a module has create/update/delete methods. Start with audit evidence and domain risk. |
| Financial mutation domains | shadow | Payment-like domains require shadow logs, domain review, and reconciliation evidence before any enforcement proposal. |
| Append-only audit logs | avoid | Merge, stale rejection, and guarded update policies do not fit append-only evidence records. |

## Permanent no-rollout zones

- IAM and security-sensitive modules.
- AI, RAG, prompt, and generation paths.
- SSE transport behavior.
- Kafka topic or schema definitions.
- DB schema and MyBatis SQL.
- Elasticsearch mapping and index structure.
- Append-only audit and idempotency ledgers.

## Shadow-only zones

- PaymentRecord mutation governance.
- Financial side-effect classification.
- Pre-mutation Kafka drift detection.
- Query repair visibility where writes are only ES backfill.

## Partial enforcement zones

- Offense Kafka `FULL_UPDATE` stale rejection.
- Offense workflow stale protection.
- Offense guarded merge for proven field preservation.
- Appeal workflow and caller-intent protection inside the domain application seam.

## Complexity ceiling

Offense has reached the highest allowed governance density. Payment must not copy Offense enforcement without production evidence. Appeal should remain a cohesive domain module, not a reusable architecture kit.

The system can tolerate documentation, tests, and deletion of stale branches. It should not add more runtime governance surfaces until one existing branch is simplified or retired.
