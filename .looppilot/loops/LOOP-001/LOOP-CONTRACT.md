# LOOP-001 Contract

## Outcome

One authenticated appeal creation operation produces at most one appeal and one
request-history row while Flutter retries retain the same operation key and treat
duplicate completion as success.

## Mode Rationale

Full Loop was selected before implementation because observed boundaries include:

- a cross-runtime Spring/Flutter response and key contract;
- durable duplicate mutation, transaction, and partial-success risk;
- authentication and server-derived identity;
- data uniqueness and concurrency behavior;
- workflow compatibility and frontend lifecycle behavior;
- multiple independently reviewable implementation Tasks; and
- required formal Finding, Rework, reverification, and recovery artifacts.

## Task DAG

`TASK-001 -> {TASK-002, TASK-003} -> TASK-004`

- TASK-001: contract and characterization.
- TASK-002: Spring idempotency transaction and response contract.
- TASK-003: Flutter operation/key lifecycle and duplicate response handling.
- TASK-004: cross-layer integration and evidence.

TASK-002 and TASK-003 may proceed in parallel only because their allowed core
files do not overlap. TASK-004 starts only after both deliveries are integrated.

## Authority

- Supervisor: scope, Task authorization, risk disposition, Finding triage, and
  Functional/Engineering/Delivery acceptance.
- Workers: implementation only within their Task contracts; no authoritative
  Ledger edits and no parent completion claims.
- Reviewers: independent judgment only; no implementation or Ledger edits.
- Integrator: authoritative transitions, integration facts, Closure, and
  Checkpoint records; no unilateral scope or acceptance decision.

## Reviewer Matrix

| Axis | Required judgment |
|---|---|
| Spec | S-1..S-8, F-1..F-9, fixed fixture/trace, excluded scope |
| Standards | role/authority boundaries, honest evidence, status sources, maintainability |
| Data | request-history uniqueness, row/result consistency, no schema change |
| Concurrency | duplicate races and transaction atomicity |
| Security | authenticated identity preserved; no client identity trust |
| Compatibility | non-duplicate and existing workflow behavior |
| Frontend | operation lifecycle, pending suppression, retry, 208 nullable data |

Spec and Standards are mandatory axes. Specialists supplement rather than replace
them. The formal Loop review must be performed by an independent Reviewer.

## Budgets

- Pre-review correction: maximum 2 cycles.
- Post-review/rework: maximum 1 cycle.
- A Major or Blocker, contract drift, repeated correction, or material context
  growth stops or escalates honestly.

## Risks

| Risk | Required control |
|---|---|
| History committed before appeal | One transaction for reservation, insert, and success result |
| Concurrent duplicate | Unique key plus deterministic duplicate resolution |
| Same key with changed body/user | Bind duplicate decision to authenticated principal and request fingerprint |
| Successful duplicate loses result | Persist/recover business ID and return success without false failure |
| Flutter repeats or rotates key incorrectly | Explicit operation lifecycle with focused state tests |
| Client identity overrides auth | Server-derived audit/driver identity and security tests |
| Existing workflow regression | Focused compatibility tests and existing relevant suite |

## Barriers

1. Contract: this contract, fixed acceptance, DAG, review matrix, authority,
   budgets, and risks recorded before implementation.
2. Implementation: TASK-002 and TASK-003 delivered within contract and locally
   verified.
3. Integration: TASK-004 establishes cross-layer trace and relevant product tests.
4. Review: independent Spec, Standards, and specialist judgments; every Finding
   triaged and resolved or explicitly accepted by the Supervisor.
5. Closure: explicit Functional, Engineering, and Delivery Acceptance plus
   unresolved findings, skipped verification, EII, residual risk, and Git facts.

## Research Brief

No current external information is material. The user fixed tool versions,
database recipe, scope, and acceptance; implementation decisions are grounded in
this isolated worktree. External pages and other Arms are out of scope.
