# EXP-005 Experiment Plan — Cross-project Replication on Final-Assignment

Experiment ID: LOOPPILOT-PHASE8-EXP-005
Project ID: FINAL-ASSIGNMENT-PHASE8-EXP005
Date: 2026-07-20
Protocol source: LoopPilot @ 298205fb87ca937e0765ef41024085538344d6e7 (frozen, read-only)
Target repo: tutict/Final-Assignment, branch experiment/looppilot-final-assignment-exp-005
Baseline: main @ ba3b49d83e1f73aeab8392fd5a5292d6961b058e (== origin/main at start, 0/0)

## Purpose

Phase 7 heuristics were calibrated from four MMGH experiments
(TypeScript/Rust/Tauri desktop app). EXP-005 tests transfer to a materially
different stack — Spring Boot 4 / Java 25 / MyBatis-Plus / Redis / Kafka /
Elasticsearch backend with a Flutter 3.44 / GetX frontend — through one
protocol-governed bounded change. This is a replication probe, NOT a strict
same-task Baseline/Lightweight/Full-Loop A/B (that is EXP-006).

## Scope

In scope: finalAssignmentBackend, final_assignment_front, `.looppilot/`,
`docs/experiments/looppilot-phase8-exp005/`.
Out of scope (read-only background at most): finalAssignmentCloud,
final_assignment_backend_go, final_assignment_backend_quarkus,
final_assignment_front_react. Forbidden: main, merge, PR, tag, release,
deploy, LoopPilot modification, real secrets/user data/production services.

## Hypotheses Under Test (from frozen Phase 7 docs)

### H1 — Lightweight proportionality
Single owner + local module + directly testable + no cross-runtime/security/
data/partial-success risk → Lightweight tendency.

### H2 — Full Loop risk triggers
Cross Spring/Flutter contract, or authn/authz, or sensitive data, or
transaction/idempotency/duplicate-write, or multi-Worker / specialist-Reviewer
value → Full Loop tendency.

### H3 — Artifact Budget
Lightweight defaults to ~4–7 protocol/experiment artifacts (provisional
heuristic, not a hard limit).

### H4 — Risk-loaded specialist Reviewers
Spec + Standards permanent; Security/Data/Compatibility/Accessibility/
Operations enabled only for matching real boundaries.

### H5 — Execution Incident separation
Agent 429/no-output, tool timeouts, Docker unavailability, dependency
failures, Flutter platform faults are Execution Infrastructure Incidents,
not automatically Product Findings.

### H6 — Load Profile proportionality
An ordinary bounded change does not load Project Finalization, Release
Readiness, or full Full-Loop history.

Verdict vocabulary per hypothesis: `supported` | `contradicted` |
`inconclusive` | `not exercised`. Contradictions MUST be recorded, not hidden.

## Counterexample-first commitments

The audit actively searches for:
1. a low-risk-looking candidate that actually needs Full Loop;
2. a cross-layer-looking candidate that actually needs only Lightweight;
3. a present hard trigger not worth implementing;
4. an Artifact Budget misfit for this project;
5. a Reviewer need MMGH never exercised;
6. a Load Profile shortfall that must be recorded but NOT fixed in LoopPilot now.

## Method

1. Stage 0 git reality check (done; recorded in BASELINE-OBSERVATIONS.md).
2. Tool + Spring + Flutter baselines, honestly recording Surefire's actual
   test scope and any infrastructure incidents.
3. Stage A audit of five candidate boundaries (A auth/session, B idempotent
   writes, C driver-scoped authorization, D WebSocket ticket lifecycle,
   E error envelope/state preservation) via read-only auditors.
4. Mode Selection Gate (16 dimensions, 0–2 each; hard-trigger review;
   legal outcomes: Lightweight / Full Loop / No implementation justified).
5. One bounded change on the selected boundary (RED→GREEN→refactor;
   no fabricated RED; characterization-first).
6. Dual-axis review + risk-loaded specialists; full validation; sensitive-data
   scan; RESULTS with H1–H6 verdicts and MMGH comparison.
7. Commits per the three-commit strategy; push experiment branch only.

## Completion Semantics

Project experiment complete ≠ Final-Assignment accepted ≠ refactor complete
≠ release ready ≠ released ≠ deployed.
