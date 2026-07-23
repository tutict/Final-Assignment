# EXP-006 Baseline Run Report

## Run Identity

- Arm: `baseline`
- Date: 2026-07-23 (Asia/Shanghai)
- Worktree: `C:\Users\tutic\IdeaProjects\Final-Assignment-exp006-baseline`
- Branch: `experiment/looppilot-final-assignment-exp-006-baseline`
- Starting HEAD: `ba3b49d83e1f73aeab8392fd5a5292d6961b058e`
- Database for database-backed verification: `traffic_exp006_baseline`
- Spring profile for database-backed verification: `test`
- Frozen result: the pushed branch tip is the authoritative final HEAD. The exact hash is reported after commit and push because a Git commit cannot contain its own hash.

No pull request, merge, release, deployment, or `main` branch change was performed.

## Scope

The run implemented the appeal POST idempotency contract and the Flutter appeal-submission lifecycle. The backend now reserves an idempotency key, creates the appeal, and records successful idempotency history within one application transaction. A database uniqueness constraint remains the concurrency boundary. Duplicate requests return HTTP 208 with a successful envelope and null data. Validation failures do not consume the key.

The Flutter client now treats a 208/null response as an already-processed success, shares an in-flight submission, retains the key after transient failures, rotates it after success or terminal failure, and invalidates stale completions after cancellation.

Changes outside this contract, including repairs to unrelated integration fixtures, were excluded.

## Resume Deviation

`RD-EXP006-001` was observed before implementation. The starting worktree was not clean:

- modified `final_assignment_front/lib/core/network/base_api_client.dart`
- modified `final_assignment_front/lib/features/api/appeal_management_controller_api.dart`
- modified `final_assignment_front/lib/features/dashboard/views/user/pages/main_process/user_appeal.dart`
- untracked `final_assignment_front/lib/features/appeal/appeal_submission_coordinator.dart`

These files were audited against the requested behavior rather than treated as verified work. The nullable API/parser changes were retained. The coordinator and UI lifecycle were corrected and covered by focused tests. This deviation is not counted as pre-run evidence.

## Acceptance Matrix

Evidence labels:

- **Observed**: directly exercised by a test, build, or source inspection in this run.
- **Inferred**: supported by observed structure/results but not independently exercised at every boundary.
- **Unverified**: not demonstrated in this run.

### Server Contract

| ID | Result | Evidence |
| --- | --- | --- |
| S-1 | Observed | The canonical sequential contract test received 201 with a non-null created appeal for the first authenticated keyed request. |
| S-2 | Observed | Repeating the same user/body/key returned 208 with a success envelope and null data. |
| S-3 | Observed | Two concurrent same-key requests completed with exactly one 201 and one 208. |
| S-4 | Observed | The concurrent contract test found exactly one appeal row for the request. |
| S-5 | Observed | The same test found exactly one idempotency-history row for the key. |
| S-6 | Observed | The history row recorded the created appeal business ID, a successful terminal status, and request trace data. |
| S-7 | Observed | An invalid request returned 400 without consuming the key; a subsequent valid request using that key returned 201. |
| S-8 | Observed + inferred | Concurrency and validation rollback behavior were observed. Atomicity is additionally supported by source inspection of the single rollback-enabled application transaction; forced infrastructure-failure rollback was not separately injected. |

### Flutter Lifecycle

| ID | Result | Evidence |
| --- | --- | --- |
| F-1 | Observed | Focused Flutter test parsed a 208/null response without a type error. |
| F-2 | Observed | The coordinator classified 208/null as successful/already processed. |
| F-3 | Observed | Repeated submit while pending returned the same future. |
| F-4 | Observed | Pending duplicate submit produced one API call and one idempotency key. |
| F-5 | Observed | A transient failure retained the key for retry. |
| F-6 | Observed | A successful retry cleared the key and the next operation generated a new key. |
| F-7 | Observed | A terminal failure cleared the key. |
| F-8 | Observed | Cancellation cleared the key, invalidated the old completion, and allowed a replacement operation with a new key. |
| F-9 | Observed + inferred | Source inspection and successful Flutter test/web build confirm the wired pending controls and retry dialog path. No manual browser interaction was performed. |

## Verification Results

Backend commands were run from `finalAssignmentBackend`. Database-backed Maven commands used the isolated database named above; credentials came only from the existing test configuration/environment and are not recorded here.

| Command | Result | Observed evidence |
| --- | --- | --- |
| `mvn -DskipTests compile` | Pass | Final run exited 0. The first attempt exposed a Java record factory/accessor name collision and was corrected before review. |
| `mvn -Dtest=AppealRecordApplicationServiceTest test` | Pass | 19 tests passed. |
| `mvn -Dtest=AppealIdempotencyContractTest test` | Pass | 3 canonical tests passed against `traffic_exp006_baseline`. |
| `mvn -Dtest=AppealIntegrationTest test` | Fail | 8 of 8 existing tests failed before appeal creation because the existing vehicle fixture omitted production-schema `owner_id_card`; prerequisite vehicle POST returned 409. |
| `mvn test` | Fail | Existing integration suites had broader fixture/context failures. The new canonical test and unit tests passed. |
| `mvn -DskipTests package` | Pass | Packaging exited 0. |
| `dart format --output=none --set-exit-if-changed lib test` | Fail | The command detected broad pre-existing formatting drift and modified unrelated files. All unrelated formatter churn was restored; intended new coordinator/test files were formatted separately. |
| `flutter test test/features/appeal/appeal_submission_coordinator_test.dart` | Pass | 4 focused lifecycle tests passed. The first attempt exposed an incorrect test key-factory expectation and the test was corrected. |
| `flutter analyze` | Fail | Only the existing unrelated warning at `lib/features/dashboard/views/manager/pages/main_process/vehicle_list.dart:107` was reported (`unused_local_variable`). |
| `flutter test` | Pass | 14 tests passed. |
| `flutter build web --release` | Pass | Release web build completed successfully. |
| `git diff --check` | Pass | No whitespace errors in the final intended diff before report creation. |

The full Maven suite also reported existing failures in offense/fine, driver/vehicle, user/role, payment, business regression, and realtime integration areas. Kafka connection noise was observed in logs. These were recorded as baseline infrastructure/fixture evidence, not reclassified as appeal-product regressions.

## Correction Accounting

- Primary implementation cycle: 1.
- Pre-review corrective cycle 1: renamed the Java record factory that collided with an accessor; compile then passed.
- Pre-review corrective cycle 2: corrected the focused Flutter test's key-factory expectation; the focused test then passed.
- Database fixture calibration: the new canonical test fixture was adjusted to satisfy the observed production-compatible schema (vehicle owner ID, valid offense process state/number, and conditional offense-type seed). This changed test setup, not product behavior.
- Post-review corrective cycles: 0.

## Residual Risk

- The legacy appeal integration test and full Maven suite remain red because existing fixtures do not satisfy the isolated production-compatible schema and other existing integration contexts. This limits whole-repository regression confidence.
- The Flutter UI lifecycle was verified by automated coordinator tests, analysis/build results, and source inspection, but not by manual browser interaction.
- The existing idempotency schema makes the key globally unique. Cross-user reuse of an identical key is therefore treated as a duplicate; no schema change was in scope.
- A forced database or downstream failure after key reservation was not injected. Transaction rollback behavior for that path is inferred from the rollback-enabled single transaction.

## Conclusion

The focused server and Flutter acceptance contracts are observed passing. Repository-wide verification is not fully green for the baseline reasons recorded above, so this report does not claim unrestricted project validation or compatibility beyond the commands and environment observed in this run.
