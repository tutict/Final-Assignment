# Governance Architecture Decision Records Pack

Status: accepted

This pack records the architecture decisions that came out of the Appeal rollout, Offense partial enforcement, Payment shadow audit, and governance convergence review.

The purpose is to stop governance from turning into a platform. Future work should treat these ADRs as boundaries, not as a backlog for more abstraction.

## ADR-001: governance/core remains vocabulary-only

### Context

The backend now has `governance/core` vocabulary for semantic mutation type, side-effect policy, after-commit coordination, and read/write model boundaries. Appeal, Offense, and Payment proved that these words are useful across domains, but they also proved that domain behavior diverges quickly.

Appeal uses application-service seams and domain policy. Offense has stale rejection, guarded merge, rollout visibility, and compatibility logging. Payment is intentionally shadow-only because financial mutation behavior needs more evidence before enforcement.

### Decision

`governance/core` stays vocabulary-only. It may describe stable concepts, but it must not become a framework, runtime registry, annotation model, generic repository layer, or policy engine.

Core is allowed to contain small pure types such as mutation vocabulary and after-commit coordination contracts. Domain-specific policy stays in the owning module.

### Consequences

- The codebase keeps a shared language without forced implementation reuse.
- Domains can adopt governance incrementally without migration pressure.
- Duplication is acceptable when it preserves domain clarity and rollback safety.
- Future contributors must not promote Payment or Offense behavior into core just because names look similar.

### Rejected alternatives

- A generic governance engine that owns classification and enforcement.
- Annotation-driven governance on service methods.
- Runtime scanning or registration of governed modules.
- Global merge policies for all entities.
- Global stale update rules.

### Rollback philosophy

Core vocabulary should be removable from a domain without changing external contracts. If a core concept starts requiring domain-specific exceptions, rollback by moving that behavior back into the domain package instead of expanding core.

### Non-goals

- No generic persistence abstraction.
- No global workflow orchestration.
- No universal event bus.
- No cross-domain enforcement.
- No schema, API, Kafka, or Elasticsearch migration.

## ADR-002: semantic governance remains domain-local

### Context

Appeal, Offense, and Payment all use semantic categories such as full update, workflow update, system update, no-op, and read repair. The categories are stable, but the classification rules are not identical.

Appeal classifies by business, workflow, and system field intent. Offense classifies create, update, delete, workflow, duplicate, Kafka action, and read repair, then applies stale and merge policy. Payment classifies controller, Kafka, workflow status, pre-mutation Kafka, and read repair only for shadow observability.

### Decision

Semantic classification is a domain-local seam. Each domain owns its classifier and its mapping from code paths to semantic intent.

Shared vocabulary may guide naming, but no domain is required to implement a shared classifier interface unless the local code already benefits from it.

### Consequences

- Semantic meaning stays close to business rules.
- Payment can remain shadow-only without inheriting Offense enforcement.
- Appeal can keep caller-intent validation without forcing it onto simpler modules.
- Similar enum values may exist in multiple domains when that avoids accidental coupling.

### Rejected alternatives

- One global classifier for every entity.
- A reflection-based field classifier.
- A central list of field ownership rules.
- A common stale or merge policy for all modules.
- Treating matching enum names as proof that behavior should be shared.

### Rollback philosophy

A domain classifier should be easy to remove with its logging and tests. If it starts driving unrelated modules, stop and split it back into domain-local policy.

### Non-goals

- No semantic DSL.
- No automatic action-to-intent registry.
- No shared field-diff engine.
- No forced migration of legacy services.

## ADR-003: rollout governance remains evidence-driven

### Context

Offense has enough evidence to enforce selected paths: stale Kafka `FULL_UPDATE` rejection, workflow stale protection, guarded merge, and controller compatibility visibility. Payment does not have that evidence yet, so it only emits shadow governance logs. Appeal enforcement is expressed through its domain application seam and workflow policy.

The convergence audit showed that rollout control is valuable only when it makes real migration risk visible. It is not a reason to add new modes, flags, or a config platform.

### Decision

Governance rollout must be evidence-driven. A path may move from shadow to compatibility or enforcement only when logs, tests, and domain review show that enforcement is safe.

Rollout state should remain explicit and local. Do not add a distributed config platform, runtime admin mutation API, or feature-flag framework for governance rollout.

### Consequences

- Payment stays shadow-only until operational evidence supports stronger action.
- Offense keeps partial enforcement only where behavior is already proven.
- Controller compatibility can remain a bridge without changing API responses.
- Future enforcement proposals must include rollback and evidence criteria.

### Rejected alternatives

- Enforce all modules once vocabulary exists.
- Add dynamic runtime rollout controls.
- Add a feature flag framework for governance.
- Treat tests alone as enforcement readiness.
- Promote shadow logs into blocking behavior without production evidence.

### Rollback philosophy

Every enforcement branch must have a local compatibility or shadow fallback. If enforcement causes operational risk, rollback should mean disabling that branch or reverting a small domain seam, not changing shared infrastructure.

### Non-goals

- No rollout dashboard.
- No runtime admin endpoint.
- No distributed config server.
- No automatic enforcement migration.

## ADR-004: some domains must never enter mutation governance rollout

### Context

The governance work was successful in selected legacy mutation domains because they had clear row ownership, explicit side effects, and observable idempotency paths. Some areas do not have those properties.

IAM and security-sensitive logic carry access-control risk. AI, RAG, prompt, and SSE code is execution and retrieval infrastructure, not entity mutation governance. SysRequestHistory acts as an idempotency and audit ledger; rewriting its semantics would damage the evidence layer used by governance itself.

### Decision

Some domains are excluded from mutation governance rollout. Exclusion is an architecture decision, not unfinished work.

Avoid rollout governance for IAM, security internals, AI/RAG, prompt handling, SSE streams, append-only audit logs, and idempotency ledgers. Retrieval code may receive retrieval-safe boundaries, but not mutation enforcement.

### Consequences

- Governance does not become a universal architecture tax.
- Security and AI behavior remain owned by their specialized designs.
- Audit and idempotency records stay trustworthy as evidence.
- Contributors have a clear reason to reject future overreach.

### Rejected alternatives

- Govern every module with the same lifecycle.
- Apply stale-write rules to append-only ledgers.
- Treat retrieval pipeline changes as mutation governance.
- Add security governance into the same rollout policy.

### Rollback philosophy

If governance touches an excluded domain, rollback should remove that governance immediately unless a new ADR explicitly narrows and justifies the exception.

### Non-goals

- No IAM rollout policy.
- No AI/RAG mutation governance.
- No prompt governance framework.
- No SSE governance framework.
- No audit-log merge policy.

## ADR-005: retrieval and read governance differs from mutation governance

### Context

Appeal introduced read projections and retrieval-safe views. Offense and Payment expose query repair behavior through logs and ES backfill paths. These are not the same as mutation governance.

Mutation governance controls writes, stale updates, field preservation, workflow ownership, and side effects. Retrieval governance controls what can be safely read, indexed, repaired, or exposed to retrieval consumers.

### Decision

Read and retrieval governance remain separate from mutation governance.

Retrieval governance may define whitelisted read views, projection assemblers, and read-repair observability. It must not inherit mutation rollout modes or enforcement rules.

### Consequences

- Retrieval-safe fields can be reviewed without changing write behavior.
- Query repair can stay observable without becoming write enforcement.
- Sensitive financial, identity, and operational fields stay out of retrieval views unless explicitly whitelisted.
- ES backfill and DB fallback remain operational concerns, not proof of mutation readiness.

### Rejected alternatives

- Use mutation policy to decide retrieval safety.
- Treat read repair as a normal mutating workflow.
- Reuse write entities directly as retrieval payloads.
- Add one global read/write governance engine.

### Rollback philosophy

Retrieval governance should be reversible by removing projection or whitelist code. It must not require database schema changes, ES mapping changes, or API response changes to roll back.

### Non-goals

- No ES mapping migration.
- No retrieval framework.
- No AI prompt changes.
- No broad read model rewrite.

## ADR-006: complexity budget and convergence policy

### Context

The governance footprint is now meaningful: Appeal has a broad domain seam, Offense has partial enforcement with rollout and observability, Payment has a shadow audit seam, and core vocabulary exists. The convergence audit found that the system is close to its acceptable governance complexity ceiling.

The next architecture risk is not missing capability. The risk is framework creep: adding modes, engines, registries, or cross-domain abstractions that make rollback hard.

### Decision

Governance is now in convergence mode. New capability expansion is blocked by default.

Any new enforced branch must be justified by evidence and paired with a complexity reduction, such as removing a dead branch, simplifying a policy, or retiring duplicated logging that has served its purpose. New core vocabulary requires a separate ADR and should be treated as exceptional.

### Consequences

- Future work favors documentation, measurement, and simplification.
- Shadow-only domains do not automatically progress.
- Offense enforcement does not become a template for Payment.
- Architecture reviews can reject broad governance proposals early.

### Rejected alternatives

- Continue adding governance to every legacy module.
- Add more rollout modes for finer control.
- Build a governance platform around current seams.
- Normalize every domain into one architecture shape.
- Treat duplication as worse than accidental coupling.

### Rollback philosophy

Rollback must stay local. The preferred rollback is deleting a domain seam or reverting a small policy change. If rollback requires changing core or multiple domains, the design has exceeded the complexity budget.

### Non-goals

- No governance platform.
- No generic engine.
- No auto-governance.
- No new rollout vocabulary.
- No cross-module sweeping migration.
