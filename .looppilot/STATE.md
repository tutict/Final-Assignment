# LoopPilot Shared State

Status: active
Updated: 2026-07-20
Updated by: EXP-005 Supervisor

## Objective

Execute LoopPilot Phase 8-A / EXP-005: cross-project replication of the frozen
Phase 7 protocol (LoopPilot @ 298205fb) on the Final-Assignment Spring Boot +
Flutter system, ending in one bounded, reviewed, validated full-stack change
and a heuristic-transfer verdict for H1–H6.

## Success Criteria

- Stage 0 git reality check recorded; main untouched; experiment branch only.
- Tool + build baselines recorded honestly (including infrastructure incidents).
- 3–5 candidate boundaries audited with citable evidence; counterexamples sought.
- Mode Selection Gate completed before any product code change.
- One bounded change implemented (or "No implementation justified" recorded).
- Focused Spring + Flutter tests, review, full validation, RESULTS with H1–H6.

## Mode Selection

- Candidate mode: **Lightweight** (decided 2026-07-20, before implementation)
- Evidence and hard triggers: MODE-SELECTION.md — score 11/32; only sustained
  trigger = Security-Reviewer need; recorded protocol tension re specialist
  trigger vs proportionality
- Artifact Budget target: change-governance 4–7 (CHANGE-CONTRACT/REVIEW/
  RESULTS + compact .looppilot updates); experiment-mandated reporting
  exceeds and is explained in MODE-SELECTION.md
- Escalation conditions: Major/Blocker finding; Spring product code forced
  into scope; second same-defect correction; contract drift
- Supervisor decision: Lightweight + Spec/Standards/Security review
- Integrator record: recorded in MODE-SELECTION.md (no status ownership)

## Current Progress

- Five-candidate audit complete (FINAL-ASSIGNMENT-CROSS-LAYER-AUDIT.md);
  preliminary-vs-deep divergence on Candidate B detected and resolved by
  Supervisor line-level verification (worker-reliability evidence).
- Selected bounded change: A-slice session-recovery classification
  (CHANGE-CONTRACT.md). B and D recorded as future Full-Loop-shaped work.
- Baselines recorded (BASELINE-OBSERVATIONS.md): mvn compile/package green,
  mvn test 76/87 pre-existing red (LoginAttemptGuard cascade), Flutter
  10/10 green, web build green, 4 pre-existing format deviations, EII-1
  Docker recovered.
- Next: RED tests → implementation → GREEN → reviews → validation → RESULTS.

## Blockers

- None blocking; Docker availability determines Testcontainers baseline depth.
