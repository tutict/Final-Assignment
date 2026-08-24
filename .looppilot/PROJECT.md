# Project Engineering Context

Project ID: FINAL-ASSIGNMENT-PHASE8-EXP005
Project type: delivery-only behavioral experiment
Status: active
Updated: 2026-07-20
Protocol source: LoopPilot @ 298205fb87ca937e0765ef41024085538344d6e7 (frozen, read-only)

## Problem

LoopPilot Phase 7 heuristics (Mode Selection, Artifact Budget, Load Profiles,
risk-loaded specialist Reviewers, Execution Infrastructure Incident
classification) were calibrated only on MMGH (TypeScript/Rust/Tauri) evidence.
EXP-005 tests whether they transfer to a materially different stack:
Spring Boot 4 / Java 25 backend + Flutter 3.44 / Dart 3.12 frontend.

## Users and Actors

- Supervisor/Integrator: the coordinating agent for EXP-005.
- Workers/Reviewers: delegated only if the selected mode justifies them.
- Repository owner: tutict (experiment branch only; main untouched).

## Core Use Cases

1. Load frozen protocol into a second real project.
2. Audit the Spring/Flutter contract surface (5 candidate boundaries).
3. Select mode from evidence; implement exactly one bounded change.
4. Review, validate, and report support/contradiction for Phase 7 heuristics H1–H6.

## Included Scope

- finalAssignmentBackend (Spring Boot main backend)
- final_assignment_front (Flutter main frontend)
- docs/experiments/looppilot-phase8-exp005/
- .looppilot/ project context
- Branch: experiment/looppilot-final-assignment-exp-005 only

## Excluded Scope

- finalAssignmentCloud, final_assignment_backend_go,
  final_assignment_backend_quarkus, final_assignment_front_react
  (read-only compatibility background only; never implementation targets)
- main branch, merges, PRs, tags, releases, deployments
- LoopPilot repository (frozen; no calibration from this single experiment)
- Real secrets, real user data, production services, paid AI providers

## Business Invariants

- Experiment completion ≠ Final-Assignment accepted ≠ refactor complete
  ≠ release ready ≠ released ≠ deployed.
- Evidence labels (observed / inferred / unmeasured / not applicable) are
  never silently upgraded.
- Execution Infrastructure Incidents stay separate from Product Findings.
- One authority per status: this file owns Project status; mode decision is
  recorded in docs/experiments/looppilot-phase8-exp005/MODE-SELECTION.md.

## Pre-existing Excluded Work

- `.gitignore` carried an uncommitted local modification (tool-cache ignore
  rules) before EXP-005 began. It is preserved, excluded from experiment
  commits, and left for the repository owner.

## Mode Decision

Recorded after the cross-layer audit in
`docs/experiments/looppilot-phase8-exp005/MODE-SELECTION.md`. Not predetermined.
