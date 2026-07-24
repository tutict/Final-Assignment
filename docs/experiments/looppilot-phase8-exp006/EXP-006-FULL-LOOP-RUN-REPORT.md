# EXP-006 Full Loop Arm Run Report

## Outcome

**Blocked / not delivered.** The Contract Barrier passed, but mandatory backend
and frontend implementation Tasks did not submit reviewable Deliveries after
bounded Worker and replacement attempts. The Loop and Project are Blocked, not
Closed or accepted.

## Scope

The fixed target was Spring `POST /api/appeals` idempotency plus Flutter appeal
creation key/retry lifecycle for S-1..S-8 and F-1..F-9. Schema, migrations,
dependencies, authentication design, unrelated backend/React, release, and deploy
remained excluded.

## Mode and Process Evidence

- Observed: Full Loop mode was selected before implementation for cross-runtime,
  transaction, identity, data, concurrency, compatibility, and frontend risks.
- Observed: one Loop and the fixed DAG
  `TASK-001 -> {TASK-002, TASK-003} -> TASK-004` were recorded.
- Observed: TASK-001 characterization passed independent Spec and Standards
  review and was Integrated; its Delivery remains unattributed under INFO-001.
- Observed: TASK-002 and TASK-003 ended blocked/partial after EII-004 through
  EII-009; TASK-004 did not start.

## Verification Table

| Check | Result | Evidence classification |
|---|---|---|
| Branch | `experiment/looppilot-final-assignment-exp-006-full-loop` | Observed |
| Fixed product base | `ba3b49d83e1f73aeab8392fd5a5292d6961b058e` | Observed |
| Failed-run preservation commit | `b575d143112e9a946a5f1450e2083b29fa2c84ac` | Observed pushed evidence boundary |
| Reviewed metadata HEAD | `a4f36d463d5429f3a7cbefffaf1766df697524db` | Observed before this post-review correction |
| Final metadata correction | Commit containing this report; exact SHA verified/reported after commit | Observed boundary; a commit cannot contain its own SHA |
| Initial worktree | Clean before Full Loop artifacts | Observed |
| Toolchain | Java 25; Maven 3.9.12; Flutter 3.44.4; Dart 3.12.2 | Observed |
| MySQL service | MySQL80 running | Observed |
| Credential environment presence | `TEST_DB_PASSWORD`, `SPRING_DATASOURCE_PASSWORD`, `DB_PASSWORD`, `MYSQL_PWD`: no | Observed presence only; no value read or persisted |
| Focused backend unit command | Timed out after 124 seconds; no result | Observed EII-002; not pass/fail evidence |
| Backend implementation/tests | Incomplete; no Delivery/result | Observed blocked state |
| Flutter implementation/tests | Partial/unreviewed; no Delivery/result | Observed blocked state |
| Database fixture/row counts | Not run | Unverified |
| Cross-layer key trace | Not run | Unverified |
| Response-read loss | Modeled only in preserved unintegrated partial Flutter tests | No Delivery; not independently reviewed, executed, or accepted; no acceptance evidence and no live transport-loss claim |
| Integrated Spec/Standards/specialist review | Not reached | Observed skipped barrier |
| Final pre-commit `git diff --check` | Passed | Observed |
| Commit/push/remote match | Preservation commit pushed and reviewed metadata HEAD matched local/remote before this correction | Observed; final correction is verified after commit |
| Clean worktree | Clean at reviewed metadata HEAD; final correction cleanliness is verified after commit | Observed before correction |

## Acceptance

- S-1..S-8: **NOT ACCEPTED**; no completed backend implementation or database
  trace exists.
- F-1..F-9: **NOT ACCEPTED**; partial Flutter code/tests are unreviewed and have
  no submitted test result.
- Fixed cross-layer fixture: **NOT ACCEPTED**; no Flutter key = Spring header =
  request history = retry trace or one-row proof exists.
- Functional Acceptance: **NOT MET**.
- Engineering Acceptance: **NOT MET**.
- Product Delivery Acceptance: **NOT MET** because implementation Deliveries,
  TASK-004 integration evidence, and independent implementation review are absent.
- Evidence preservation: **ACHIEVED** for the preservation commit/push,
  local/remote match, and clean worktree. These Git facts do not satisfy product
  Delivery Acceptance.

## Incidents and Limitations

EII-001 through EII-009 are preserved in the Loop integration incident record.
They are execution/coordination incidents, not Product Findings. No implementation
Review occurred, so the lack of Product Findings is not evidence of quality.

Partial product/test edits remain unintegrated. The Supervisor authorized the exact
failed-run preservation commit/push recorded above; that action does not approve
either Task or convert the partial code into product delivery. This report does
not claim release or deployment readiness and grants no release, deployment,
migration, or traffic-change authority.

The preserved partial Flutter tests contain a modeled response-read-loss scenario.
They have no Delivery, were not independently reviewed, were not executed or
accepted, and provide no acceptance evidence. No live transport-level response
loss was tested or claimed.
