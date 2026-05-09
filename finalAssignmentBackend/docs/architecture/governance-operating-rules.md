# Governance Operating Rules

Status: accepted

These rules govern future backend governance work after the convergence audit. They are intentionally restrictive.

## Hard rules

- Do not add a new rollout mode without production evidence and a new ADR.
- Do not add a generic governance engine.
- Do not add a governance framework, DSL, annotation model, reflection registry, or runtime scanner.
- Do not force cross-domain abstraction from similar vocabulary.
- Do not move domain stale rules, merge rules, workflow ranks, or financial semantics into `governance/core`.
- Do not change API paths, response JSON, Kafka topics or schemas, DB schema, MyBatis SQL, or Elasticsearch mapping as part of governance.
- Do not add governance to IAM, AI/RAG, prompt, SSE, append-only audit logs, or idempotency ledgers.
- Do not promote shadow behavior to enforcement without evidence from logs and targeted tests.
- One new enforced branch requires one complexity reduction.

## Complexity budget rules

- `governance/core` is vocabulary-only. Expanding it is exceptional.
- Offense is at the complexity ceiling for enforcement-heavy governance.
- Payment is shadow-only until financial consistency evidence justifies a separate ADR.
- Appeal may evolve inside its application/domain seam, but it must not become the template for every module.
- Duplicated small domain policies are acceptable when they avoid accidental coupling.
- Any proposal that needs more than one module migration is presumed too broad.
- Any proposal that cannot be rolled back by removing a small domain seam is presumed too complex.

## Rollback discipline

- Every governance change must be locally reversible.
- Prefer deleting a domain seam over modifying shared core.
- Enforcement branches need a compatibility or shadow fallback.
- Logging-only changes must not become required for successful mutation.
- Rollback must not require DB, Kafka, ES, API, or frontend changes.
- If rollback would affect unrelated modules, the design has already exceeded the budget.

## Shadow-first discipline

- New governance starts as read-only audit or shadow logging.
- Shadow logs must identify source, semantic intent, rollout state, and entity id when safe.
- Shadow logs must avoid sensitive fields such as identity, bank, transaction, token, credential, and prompt content.
- Shadow evidence must be reviewed before enforcement is proposed.
- Shadow-only domains are allowed to stay shadow-only permanently.

## Enforcement preconditions

Enforcement requires all of the following:

- A documented failure mode that exists in the current system.
- Structured logs showing the frequency and source of the risk.
- Targeted tests for classification, decision creation, and rollback behavior.
- A domain-specific policy with explicit boundaries.
- A compatibility plan for existing controller or Kafka traffic.
- A rollback plan that touches no external contract.
- Review that confirms the rule is not a framework in disguise.

## Contributor checklist

Before changing governance code, answer these questions:

- Is this evidence-driven, or only architecture enthusiasm?
- Can this stay domain-local?
- Can this be shadow-only?
- Does this add a mode, vocabulary item, framework, registry, or annotation?
- Does this make rollback harder?
- Does this touch a permanent no-rollout zone?
- Does this reduce complexity somewhere else?

If the answer suggests expansion without evidence, stop.

## Stop conditions

Stop the design immediately if it starts to include:

- A global governance platform.
- A semantic or rollout DSL.
- Automatic governance discovery.
- A generic merge engine.
- A generic stale update engine.
- A universal workflow governance layer.
- Cross-domain migration just to normalize style.

Governance is successful when it narrows operational risk without becoming a second application architecture.
