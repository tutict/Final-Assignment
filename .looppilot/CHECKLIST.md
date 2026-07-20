# Parent Goal Checklist

Goal ID: FINAL-ASSIGNMENT-PHASE8-EXP005
Status: active
Updated: 2026-07-20
Supervisor: EXP-005 coordinating agent
Integrator: same agent (recorded distinctly per protocol)
Source of truth: current user instruction and host-native plan; this file is a projection.

## Parent Goal

Cross-project replication of frozen LoopPilot Phase 7 protocol on
Final-Assignment (Spring Boot + Flutter), one bounded change, H1–H6 verdicts.

## Mode Gate

- [x] Problem and Scope understood.
- [x] Frozen LoopPilot baseline verified (298205fb).
- [x] Stage 0 git reality check completed; pre-existing work preserved.
- [x] Experiment branch created.
- [x] Tool and build baselines recorded (incl. as-found red baseline + EII-1/EII-2).
- [x] Cross-layer audit completed (candidates A–E, with B/C deep-pass corrections).
- [x] Counterexample search recorded (all six types).
- [x] Supervisor mode decision recorded before implementation (Lightweight, 11/32, tension recorded).
- [x] Artifact Budget and escalation conditions recorded.
- [ ] Contract Barrier passed (n/a — Full Loop not selected).

## Delivery

- [x] Bounded change implemented (auth_service.dart session-recovery classification; commit 0d6c93cb).
- [x] Focused Spring tests pass (6/6, Surefire-includable names, standalone and in-suite).
- [x] Focused Flutter tests pass (10/10 new; 20/20 total; 4 observed RED pre-change).
- [x] Spec + Standards + Security review recorded; 0 Major/Blocker; corrections reverified by original reviewers.
- [x] Full validation run (compile/package green; full mvn test pre-existing red disclosed as-found 76/87 → corrected-env 54/93; dart format touched-files clean; analyze 1 pre-existing; build web green).
- [x] Sensitive data / artifact scan clean (no secrets, no build artifacts, dependency files untouched).
- [x] RESULTS.md with H1–H6 verdicts and MMGH comparison.
- [ ] Commits pushed to experiment branch only; main untouched (checked at final push).

Only evidenced integrated items may be checked.
