# EXP-005 Results — Cross-project Replication on Final-Assignment

Date: 2026-07-20. Mode executed: Lightweight + independent Spec/Standards/
Security review. Protocol source: frozen LoopPilot @ 298205fb (read-only,
unmodified). Branch: experiment/looppilot-final-assignment-exp-005.
Commits: e7ae9029 (baseline/audit/mode), 0d6c93cb (implementation/tests),
plus the review/results commit carrying this file.

## What was delivered

One bounded product change: Flutter `AuthService` now classifies refresh
outcomes (terminal rejection vs transient failure); transient failures no
longer destroy valid sessions or delete server-honored refresh tokens.
Evidence: 4 tests observed RED pre-change → 20/20 Flutter tests green
post-change; 6/6 new Spring characterization tests green (standalone and
in-suite); three independent reviews passed with zero Major/Blocker;
corrections reverified by the original reviewers (Standards improved to
PASS, Spec stands PASS-WITH-FINDINGS with two recorded Minor residuals).

Delivered ≠ Final-Assignment accepted ≠ refactor complete ≠ release ready
≠ released ≠ deployed.

## H1–H6 verdicts

### H1 — Lightweight proportionality: **supported**
The selected boundary (single owner file, direct characterization tests, no
partial-success/data risk, trivial rollback) completed in one session under
Lightweight with full review coverage. Nothing in execution suggested Full
Loop machinery would have added control value: no task ledger ever had a
second concurrent writer, no integration record would have carried facts the
per-side test runs didn't.

### H2 — Full Loop risk triggers: **supported, with two recorded tensions**
Supported: the two candidates whose honest repair genuinely needs multi-part
coordination (B duplicate-record chain: coordinated 208-body contract change
+ multi-site key lifecycle; D WS revocation: registry kill + dual-side close
policy) are exactly the ones the hard-trigger list flags — the triggers
correctly identified where Full-Loop-shaped work lives.
Tension 1: read literally, the frozen text makes "needs a Security Reviewer"
both a hard trigger and a Lightweight-escalation condition, which would
escalate ANY security-adjacent one-file change — contradicting the same
protocol's proportionality and anti-inflation rules. EXP-005 ran Lightweight
+ one risk-loaded Security review under the experiment instruction's explicit
provision, and it worked (the Security review produced real accepted-risk
records without Full Loop overhead). Candidate protocol clarification for the
future — NOT applied to frozen LoopPilot.
Tension 2: hard-trigger DISPOSITIONS are audit-depth-dependent. Candidate B
initially read as "trigger present but mitigated" from a preliminary audit
pass and reversed to "live defect chain" under the deep pass. A shallow audit
plus the trigger list alone would have produced a wrong mode rationale in
either direction.

### H3 — Artifact Budget (4–7): **supported for change governance;
misfit recorded for experiment reporting**
Change-governance artifacts: CHANGE-CONTRACT, REVIEW, RESULTS + compact
.looppilot projections = within target. Total repository artifacts including
experiment-mandated reporting (PLAN, BASELINE, AUDIT, MODE-SELECTION,
SCORECARD, OBSERVATIONS): 14 — double the budget for reasons owned by the
Phase-8 experiment design, not by process ceremony. The budget heuristic
remains useful ONLY if "protocol artifacts" is read as change-governance
artifacts; meta-experiment reporting needs its own accounting.

### H4 — Risk-loaded specialist Reviewers: **supported, with one taxonomy note**
Security was loaded for a real boundary and earned its cost (net-posture
analysis; SF1 retention-window and SF2 amplification accepted-risk records
that neither Spec nor Standards would have produced). Data, Operations,
Accessibility were correctly NOT loaded — none of their risk signatures
existed in scope. Taxonomy note: this change's compatibility dimension
(client consumption of an unchanged server status contract) fit naturally
inside Spec review; a separate Compatibility axis would have duplicated it.
The MMGH-derived reviewer table (whose Compatibility row is literally
"TypeScript/Rust or Web/Tauri contracts") transferred by analogy, not by
letter — mild evidence of MMGH-stack overfitting in the table's wording,
none in its principle.

### H5 — Execution Incident separation: **supported, heavily exercised**
- EII-1: Docker daemon down at start; recovered; zero product impact.
- EII-2 (the experiment's most instructive event): the as-found baseline's
  76/87 test failures were triggered by the local test DB's refresh_tokens
  table still being varchar(255) while the repo ships (but nothing applies)
  the migration db/refresh_tokens_alter_token_text.sql for ~2KB ML-KEM
  tokens — every login 401'd, and the login guard amplified the storm into
  429 lockouts. Classified as infrastructure-class (stale local dependency
  state), repaired by applying the repo's own migration, NOT converted into
  a Product Finding — and correctly so: post-repair, the entire
  AuthIntegrationTest (11/11) and AppealIntegrationTest (8/8) went green
  with zero product-code changes.
- The classification discipline changed the diagnosis twice (guard-design →
  composite schema-drift + guard-amplifier) without ever fabricating a
  product defect. Separation held under pressure.
- Delegation reliability: 10 delegated tasks (5 auditors, 3 reviewers, 2
  reverifications), zero no-output/429 worker incidents (contrast MMGH
  EXP-001/EXP-004 worker failures). New failure mode observed instead:
  preliminary auditor summaries asserted nonexistent mitigations on
  candidates B and C, reversed by deep passes and Supervisor line-level
  verification — worker-report fabrication risk is real and audit-depth
  plus supervisor verification is the working countermeasure.

### H6 — Load Profile proportionality: **supported, one gap recorded**
Loaded: Core (6 frozen docs + templates) + Lightweight set. Never loaded:
Full-Loop history, Loop Map, ledgers, Project Finalization, Release
Readiness, Checkpoint (no recovery occurred). Gap: the frozen profiles
assume a green baseline; this project's baseline was deeply red for
environmental reasons, and no profile guidance covers "establish an honest
baseline in a broken environment before judging your own change" — EXP-005
improvised (as-found baseline vs corrected-environment baseline, both
recorded). Candidate future guidance; not applied now.

## Corrected-environment validation summary

- Spring: compile ✓ (2:48), package ✓ (12.5s); focused new classes 6/6 ✓.
  Full `mvn test`: as-found 87 run / 66F+10E → corrected-environment 93 run
  (incl. 6 new) / 45F+9E. Post-repair failures follow the alphabetical
  class order: appeal (8/8 ✓), auth (11/11 ✓), the two new classes (6/6 ✓),
  then progressive collapse (driver 2F → offense/payment/realtime/user-role
  ~all-F) — the residual cascade is the login guard's 40/min-per-IP budget
  vs ~87 per-test logins (successful logins still consume the IP budget:
  recordSuccess clears only the account key), plus BusinessRegression's
  independent pre-existing failures (deprecated-path 401-before-404,
  envelope unification). All pre-existing on main; none attributable to the
  EXP-005 change (which touches no Spring product code).
- Flutter: pub get ✓; format — only the 4 pre-existing main-baseline files
  fail the repo-wide check, both touched files clean; analyze — exactly the
  1 pre-existing warning; tests 20/20 ✓; `flutter build web --release` ✓.
- Repository: `git diff --check` clean; no dependency-file changes
  (pom.xml/pubspec.yaml/pubspec.lock hashes unchanged from baseline);
  no build artifacts tracked; secret/PII scan of the full diff clean (new
  Java tests reference only the repo's pre-existing seeded test
  credentials); `.gitignore` pre-existing user modification preserved
  uncommitted.

## MMGH (EXP-001…004) vs Final-Assignment (EXP-005)

| Dimension | MMGH series | EXP-005 |
| --- | --- | --- |
| Stack | TypeScript/React/Rust/Tauri/SQLite desktop | Java 25/Spring Boot 4/MySQL/Redis/Kafka/ES + Dart/Flutter/GetX web |
| Domain | personal workspace app | traffic-violation management (auth, fines, appeals, payments) |
| Selected risk | snapshot policy / lifecycle hook / provider trust / SQLite partial success | cross-runtime session-recovery classification (auth domain) |
| Mode | 3×Full Loop, 1×Lightweight | Lightweight + 3 independent reviews |
| Protocol/experiment artifacts | ~32 / ~6 / 24 / 28 files | 14 files (change-governance subset ≈ 6) |
| Product diff | small extractions/contracts | 1 product file (+103/−29), 3 test files (+480) |
| Test delta | 5–6 focused tests typical | 10 Flutter + 6 Spring tests |
| Workers | implementation workers, 2 no-output events, one 429 | no implementation workers (single-owner change); 10 read-only/review delegations, 0 infrastructure failures |
| Reviewer axes | Spec+Standards (+Security/Compat or Data/Compat in Full Loops); EXP-002 self-review only | Spec+Standards+Security, all independent, with reverification cycle — first Lightweight run with fully independent review |
| Findings | 1 Major process (EXP-001), 1 Major recovery (EXP-003), 0 (EXP-004), 1 Minor (EXP-002) | 12 Minor + 2 Info, 0 Major/Blocker; 9 fixed, 5 recorded |
| Execution incidents | worker 429/no-output, remote-auth unavailable | Docker-down (recovered), test-DB schema drift (repo-shipped migration unapplied locally) |
| Recovery | checkpoint-based (EXP-002 manifest) | none needed (single session) |
| Human intervention | none recorded mid-run | none |
| Baseline state | green baselines | deeply red baseline requiring environment forensics before any change judgment |

Project complexity is NOT protocol effect: Final-Assignment is a much larger
system, but the bounded change was deliberately smaller-risk than EXP-003/004.

## Answers to the ten cross-project questions

1. Phase 7 heuristics transferred: yes — every H verdict above is supported,
   with recorded tensions rather than contradictions.
2. Counterexamples found: the specialist-trigger escalation literalism (H2
   tension 1); audit-depth dependence of trigger dispositions (H2 tension 2);
   artifact-budget accounting for meta-experiments (H3); reviewer-table
   stack-specific wording (H4); red-baseline guidance gap (H6).
3. 4–7 budget: fits change governance; unfit for experiment-mandated
   reporting (explained excess).
4. Load profiles sufficient: yes, except the red-baseline gap.
5. New Spring/Flutter risks MMGH never surfaced: pre-existing red baseline
   from environment drift; DB schema-migration lag in local envs; a
   product-side login rate limiter interacting with test design;
   framework-level envelope pluralism (7 shapes) as a standing
   compatibility hazard.
6. Specialist-trigger reasonableness: the risk-loading principle held; the
   escalation literalism needs future clarification (recorded, not applied).
7. Execution-incident classification value: high — it prevented two wrong
   diagnoses from becoming fake Product Findings and drove the environment
   repair that turned 19 unrelated tests green.
8. React/Tauri/Rust overfitting: only cosmetic (reviewer-table wording,
   SQLite-specific trigger examples); principles transferred cleanly.
9. Rules unsuited to Spring/Flutter: none found at principle level; the
   trigger examples and reviewer rows should be stated stack-neutrally.
10. EXP-006 readiness: yes — this project now has a verified environment
    recipe (DB migration state, guard behavior, Surefire scope), a candidate
    inventory with two Full-Loop-shaped boundaries (B, D) suitable for a
    strict same-task A/B, and a calibrated baseline record.

## Recommendation on LoopPilot changes

None applied (freeze respected). Candidate future calibrations, each needing
more than this single second-project data point: (a) clarify that one
risk-loaded specialist review is loadable within Lightweight, with
escalation on specialist Major findings or multi-axis coordination;
(b) state reviewer-table rows and hard-trigger examples stack-neutrally;
(c) define change-governance vs experiment-reporting artifact accounting;
(d) add red-baseline/environment-forensics guidance to the load profiles.

## Unverified (explicit)

Whole-repo Final-Assignment transformation; consistency of the Cloud/Go/
Quarkus backends and the React frontend; production MySQL/Redis/Kafka/ES;
real user data; real JWT secrets; real mobile Secure Storage; real payments;
real concurrency at scale; production WebSocket behavior; long-term
maintenance benefit; exact token cost (Token usage: unavailable); strict
Baseline/Lightweight/Full-Loop A/B; third-project replication; all-host
compatibility; release; deployment; security certification; data-reliability
certification; the universal accuracy of Phase-7 heuristics. A successful
second-project probe does NOT constitute general validation of LoopPilot.
