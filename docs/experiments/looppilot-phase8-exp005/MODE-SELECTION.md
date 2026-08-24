# EXP-005 Mode Selection Gate

Date: 2026-07-20. Decided BEFORE any product-code modification.
Supervisor decision recorded here; Integrator records, owns no status.
Candidate under decision: Candidate A narrow slice — client session-recovery
classification against the existing Spring auth status contract (see
FINAL-ASSIGNMENT-CROSS-LAYER-AUDIT.md, gap A-G1; A-G3 test gap).

## Dimension scores (0–2 each)

| # | Dimension | Score | Evidence (verified) |
| --- | --- | --- | --- |
| 1 | Spring/Flutter contract coupling | 1 | Change CONSUMES the existing cross-runtime status contract (401 terminal / 429+5xx transient); no server contract change; both sides get contract tests |
| 2 | Authentication/authorization impact | 2 | Session lifecycle & token retention policy on the client; no server auth semantics touched |
| 3 | Sensitive-data impact | 1 | Access/refresh token retention timing changes; storage mechanism, transport, logging untouched |
| 4 | Data consistency | 0 | No durable business data in scope |
| 5 | Idempotency/retry risk | 1 | Retry classification IS the subject; single-flight preserved; no mutation duplication surface |
| 6 | Partial-success risk | 0 | No multi-step mutation |
| 7 | Realtime lifecycle | 0 | WS out of scope (Candidate D explicitly deferred) |
| 8 | Backward compatibility | 1 | Public `refreshJwtToken(): Future<bool>` kept; 404 special-case preserved; server untouched |
| 9 | Number of state owners | 0 | AuthService is the single session-state owner |
| 10 | Multiple-Worker value | 1 | Spring characterization tests are separable from the Flutter change, but both are small; coordination cost ≥ parallel value |
| 11 | Specialist-Reviewer need | 2 | Security review of token retention/destruction policy is genuinely warranted |
| 12 | Integration complexity | 1 | Verified by per-side focused tests against one documented contract; no combined-runtime integration required |
| 13 | Recovery need | 0 | Single-session scope; no active Checkpoint |
| 14 | Scope uncertainty | 0 | Exact file list known up front |
| 15 | Rollback complexity | 0 | Ordinary code reversion |
| 16 | Test-environment complexity | 1 | Spring: local MySQL/Redis (present) + standalone class runs to stay under the login-rate budget + one extra Spring context for the throttle-contract test; Flutter: channel mocks only |

**Total: 11 / 32** → middle band ("10–18: 根据 hard triggers 判断").

## Hard-trigger review

| Trigger | Present? | Assessment |
| --- | --- | --- |
| Simultaneous Spring AND Flutter contract modification | No | Server contract unchanged; product change is client-side |
| Authentication/authorization | Nominally (domain) | Client session handling in the auth domain; server boundary untouched |
| Sensitive data | Nominally | Token retention policy, no exposure-surface change |
| Transactions / idempotency / duplicate writes / partial success | No | — |
| WebSocket security | No | Deferred with Candidate D |
| Multi-Worker real value | No | Verified small; coordination ≥ value (MMGH EXP-001 negative precedent) |
| Specialist Reviewer needed | **Yes — Security** | Real, and satisfiable as one risk-loaded review pass |
| Integration-only verifiability | No | Per-side tests suffice |
| Scope inexpressible in a short Change Contract | No | Contract below is short and honest |
| Active Checkpoint need | No | — |

## Decision

**Mode: Lightweight**, with permanent Spec + Standards review plus ONE
risk-loaded specialist review (Security), per the EXP-005 instruction
("根据风险增加一个专业 Review").

Rejected alternative — Full Loop: the only sustained trigger is the
specialist-review need (plus nominal domain triggers whose server cores are
verified-mitigated and untouched). Every Lightweight condition holds: single
verifiable change, single owner, one product file, direct characterization
tests, one session, trivial rollback, small cohesive surface. Frozen SKILL.md
§2 forbids inflating a small task to demonstrate the loop, and MMGH EXP-001
is the recorded negative precedent for Full-Loop cost at this size. Loading
Loop Map / Task Ledger / Finding Ledger / multi-Worker Deliveries /
Integration Record for a one-file client change would be cost without control
value.

Rejected alternative — No implementation: A-G1 is a verified product defect
with app-wide blast radius (every authenticated API call passes through the
defective path) contradicted by the server's own asserted invariant; new
characterization tests are expected to FAIL against current code (true RED),
so "tests only / no change" is not the honest outcome.

**Recorded protocol tension (for RESULTS H2/H4, not applied to frozen
LoopPilot):** the frozen mode-selection text lists "a need for a Security…
Reviewer" both as a Full-Loop hard trigger and as a Lightweight escalation
condition. Read literally, ANY security-relevant one-file change escalates to
Full Loop, which contradicts the proportionality principle the same document
establishes and the anti-inflation rule in SKILL.md. EXP-005 proceeds under
the current user instruction's explicit Lightweight+specialist provision and
records this as a calibration finding — a candidate future clarification
("specialist review is loadable in Lightweight; escalate when specialist
findings or multi-axis coordination emerge"), NOT a change made now.

## Artifact Budget (Lightweight)

Change-governance artifacts: CHANGE-CONTRACT.md, REVIEW.md, RESULTS.md,
plus compact .looppilot STATE/CHECKLIST/HANDOFF updates → within the 4–7
provisional target.
Experiment-mandated reporting (EXPERIMENT-PLAN, BASELINE-OBSERVATIONS,
CROSS-LAYER-AUDIT, MODE-SELECTION, EVALUATION-SCORECARD, OBSERVATIONS) brings
the total to ~13 — exceeding the budget for reasons owned by the experiment
design, not by change governance. Recorded as H3 evidence with this
explanation; mode reassessed and retained (the excess is reporting, not
process ceremony).

Not created (Load Profile discipline, H6): Loop Map entry, Loop Contract,
Task Ledger, Finding Ledger, Worker Deliveries, Integration Record, Loop
Closure, Project Closure, Cross-Loop Validation, Project Acceptance, Release
Readiness, Final Delivery Report, Checkpoint (no recovery active),
Context-Compaction record.

## Escalation conditions (stop Lightweight if any occurs)

Major or Blocker finding in review; scope forced into Spring product code or
a second Flutter owner file; security-boundary weakening discovered; a second
same-defect correction; contract drift from the text below; artifact growth
beyond the recorded set; cross-session recovery becoming necessary.

## Reviewer matrix for this change

| Reviewer | Status | Reason |
| --- | --- | --- |
| Spec | permanent | outcome vs contract, evidence, omissions |
| Standards | permanent | scope, safety, maintainability, test honesty (incl. Surefire include discipline) |
| Security | **loaded** | token retention/destruction policy change |
| Data | not loaded | no durable-data semantics in scope |
| Compatibility | not loaded as separate axis | status-contract compatibility folded into Spec scope: server contract is UNCHANGED and pinned by new characterization tests on both sides; a separate axis would duplicate Spec's checklist for this one-file change (recorded for H4) |
| Accessibility | not loaded | no UI interaction change |
| Operations | not loaded | no deploy/runtime obligation (EXP-005 default) |
