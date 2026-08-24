# EXP-005 Evaluation Scorecard

Scale 0–3 per item. Evidence class per item: observed / inferred /
unmeasured / not applicable. Token usage: unavailable.

| # | Criterion | Score | Class | Basis |
| --- | --- | --- | --- | --- |
| 1 | Cross-project recovery/orientation | 3 | observed | frozen HEAD verified; both repos oriented; pre-existing work isolated before any action |
| 2 | Core Load sufficiency | 3 | observed | 6 frozen docs + templates sufficed; no mid-run protocol hunting |
| 3 | Audit quality | 3 | observed | 5 boundaries, line-cited; 2 preliminary-report fabrications caught and corrected via Supervisor verification |
| 4 | Candidate diversity | 3 | observed | auth/idempotency/authz/realtime/envelope — distinct risk classes |
| 5 | Counterexample search | 3 | observed | all six mandated counterexample types addressed with findings |
| 6 | Mode-selection evidence | 3 | observed | 16 dimensions scored with citations; hard triggers individually assessed |
| 7 | Mode proportionality | 3 | observed | one-file change under Lightweight; no inflation; escalation conditions pre-recorded |
| 8 | Artifact-budget fit | 2 | observed | change subset fits 4–7; total 14 exceeds with explanation (experiment reporting) |
| 9 | Spring contract clarity | 3 | observed | terminal/transient/rotation/429 shapes pinned by running tests |
| 10 | Flutter contract clarity | 3 | observed | classification + preservation semantics contract-stated and test-pinned |
| 11 | Security invariant quality | 3 | observed | cleanup-preservation traced all paths; independent security net-assessment |
| 12 | Data/idempotency invariant quality | 2 | observed | no data mutation in scope (n/a for the change) but B-chain invariants documented for future work |
| 13 | Error/retry contract | 3 | observed | fail-safe default explicit; no auto-retry; residual A-G2/SF2 recorded |
| 14 | Scope discipline | 3 | observed | product diff = 1 file; boundary hashes unchanged; excluded impls untouched |
| 15 | Characterization quality | 3 | observed | public-API-only tests; true RED observed (4 failures) before change |
| 16 | Spring Worker value | 2 | observed | no separate Spring implementation worker (none needed); Spring test authoring by Supervisor was effective — scored for value of the choice, not the role |
| 17 | Flutter Worker value | 2 | observed | same: single-owner implementation by design; audit delegation valuable |
| 18 | Worker reliability | 2 | observed | 10/10 delegations produced output (0 infra failures) BUT 2 preliminary reports contained wrong mitigations and 1 wrong citation — caught by verification |
| 19 | Integration value | 2 | observed | per-side test verification sufficed; no combined-runtime integration performed (recorded limit) |
| 20 | Spec Review | 3 | observed | independent; 7 substantive findings incl. a contract-text error and a repo-migration discovery |
| 21 | Standards Review | 3 | observed | independent; verified staging discipline in git history; reverified to PASS |
| 22 | Specialist Review | 3 | observed | Security produced accepted-risk records unique to its axis |
| 23 | Finding specificity | 3 | observed | all 14 findings file:line-cited with scenarios |
| 24 | Rework effectiveness | 3 | observed | 9 findings fixed in one bounded pass; suite stayed green; no repeat correction |
| 25 | Execution Incident classification | 3 | observed | EII-1/EII-2 kept separate from Product Findings through two diagnosis revisions |
| 26 | Test evidence honesty | 3 | observed | red baseline reported as-found; pipeline exit-code observation error self-corrected in writing |
| 27 | Validation completeness | 2 | observed | full matrix run; full-suite green unreachable (pre-existing cascade) — disclosed, not worked around |
| 28 | Protocol cost | 2 | inferred | 14 artifacts + 10 delegations for a one-file change: acceptable for a replication experiment, high for routine work |
| 29 | Coordination cost | 2 | inferred | parallel delegation saved wall-clock; preliminary-report corrections added Supervisor verification load |
| 30 | Human intervention | 3 | observed | zero mid-run interventions required |
| 31 | Heuristic transfer | 3 | observed | H1–H6 all supported (with recorded tensions), no contradiction |
| 32 | Contradiction disclosure | 3 | observed | two H2 tensions, H3 misfit, H6 gap, diagnosis reversals — all recorded in place |
| 33 | Closure honesty | 3 | observed | delivered ≠ accepted ≠ released stated; unverified list explicit |

**Total: 90/99.**

Not-applicable notes: no Checkpoint/recovery cycle occurred (single
session), so recovery-specific behaviors are unmeasured this round; item 12
scores the documented invariants, not exercised mutations; items 16–17 score
the worker-structure decision (delegating audit/review, not implementation)
rather than pretending implementation workers existed.
