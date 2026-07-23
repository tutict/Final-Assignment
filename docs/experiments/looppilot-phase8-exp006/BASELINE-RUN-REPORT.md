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

The fixed cross-layer fixture key is `EXP006-CROSS-LAYER-KEY-0001`. The Spring test sends it as an HTTP `Idempotency-Key` and reads the same value from request history. The Flutter test captures the same literal in its request callback. This is a traceable response-loss model, not a claim that a live Flutter process was connected to the Spring test during one request.

### Server Contract

| ID | Result | Evidence |
| --- | --- | --- |
| S-1 | Observed | The authenticated keyed create using K returned 201 and produced one appeal row plus one request-history row. |
| S-2 | Observed | Repeating the same user/body/K returned HTTP 208 with `success=true` and `data=null`; the appeal count remained one. |
| S-3 | Observed | The duplicate response was a successful `ApiResponse`, not a contradictory failure; the canonical test asserted `success=true`. |
| S-4 | Observed | A new logical operation with K2 returned 201 and produced a second appeal row. |
| S-5 | Observed | Same-key response retry was exercised by the 208 request and did not repeat the business insert. |
| S-6 | Observed | The request body attempted a spoofed driver ID; the stored row preserved authenticated `testuser` and the authenticated driver ID. |
| S-7 | Observed | Sequential and concurrent same-key assertions both found exactly one matching appeal row. |
| S-8 | Observed + inferred | Existing unkeyed create/workflow unit coverage passed. Non-duplicate integrity failure was observed as 409 with no appeal/history rows; transaction atomicity beyond this injected failure remains inferred from the rollback-enabled service transaction. |

### Flutter Lifecycle

| ID | Result | Evidence |
| --- | --- | --- |
| F-1 | Observed | The response-loss model retried a transient network outcome with the same key. |
| F-2 | Observed | Duplicate submit while pending shared one future, one call, and no new key. |
| F-3 | Observed | The appeal nullable path parsed HTTP 208/null without executing the legacy global `null as T` shortcut, raising a TypeError, or reporting false failure. |
| F-4 | Observed | The coordinator classified nullable 208 as terminal successful/already processed, cleared the key, and made no extra create call. |
| F-5 | Observed | After a completed success, the next logical operation generated a new key. |
| F-6 | Observed | Terminal validation failure and cancellation released the old operation context; stale cancellation completion was ignored. |
| F-7 | Observed | Transient network/timeout failure retained the key for retry. |
| F-8 | Observed | Successful completion cleared the active submission context. |
| F-9 | Observed + inferred | The duplicate-success call count and coordinator state were observed; page-state preservation and dialog behavior were source-inspected, not manually exercised in a browser. |

## Verification Results

Backend commands were run from `finalAssignmentBackend`. Database-backed Maven commands used the isolated database named above; credentials came only from the existing test configuration/environment and are not recorded here.

| Command | Result | Observed evidence |
| --- | --- | --- |
| `mvn -DskipTests compile` | Pass | Post-review rework run exited 0. |
| `mvn -Dtest=AppealRecordApplicationServiceTest test` | Pass | Post-review rework run passed 22 tests, including key-length, duplicate-only mapping, and non-duplicate propagation tests. |
| `mvn -Dtest=AppealIdempotencyContractTest test` | Pass | Post-review rework run passed 5 tests against `traffic_exp006_baseline`, including the fixed key, K2, identity, 400, and 409 rollback cases. |
| `mvn -Dtest=AppealIntegrationTest test` | Fail | 8 of 8 existing tests failed before appeal creation because the existing vehicle fixture omitted production-schema `owner_id_card`; prerequisite vehicle POST returned 409. |
| `mvn test` | Fail | Existing integration suites had broader fixture/context failures. The new canonical test and unit tests passed. |
| `mvn -DskipTests package` | Pass | Post-review rework packaging exited 0. |
| `dart format --output=none --set-exit-if-changed lib test` | Fail | The command detected broad pre-existing formatting drift and modified unrelated files. All unrelated formatter churn was restored; intended new coordinator/test files were formatted separately. |
| `flutter test test/features/appeal/appeal_submission_coordinator_test.dart` | Pass | Post-review rework focused lifecycle run passed 5 tests, including the fixed-key response-loss/208 terminal-success case. |
| `flutter analyze` | Fail | Only the existing unrelated warning at `lib/features/dashboard/views/manager/pages/main_process/vehicle_list.dart:107` was reported (`unused_local_variable`). |
| `flutter test` | Pass | Post-review rework full Flutter run passed 15 tests. |
| `flutter build web --release` | Pass | Release web build completed successfully. |
| `git diff --check` | Pass | Final pre-stage run exited 0 after generated Flutter registrants were restored; only line-ending normalization warnings were emitted. |

The first post-review isolated Maven invocation was an execution-infrastructure incident: PowerShell split JDBC ampersands when the URL was passed as a Maven argument, so no tests ran. The established test-environment URL invocation then passed; no product conclusion was drawn from the failed invocation.

The full Maven suite also reported existing failures in offense/fine, driver/vehicle, user/role, payment, business regression, and realtime integration areas. Kafka connection noise was observed in logs. These were recorded as baseline infrastructure/fixture evidence, not reclassified as appeal-product regressions.

## Review Findings and Rework

The sole authorized post-review corrective cycle addressed these findings:

1. `AppealIdempotencyService` previously converted every `DataIntegrityViolationException` into HTTP 208. It now validates nonblank keys at the production schema limit of 64 characters, maps only `DuplicateKeyException` to duplicate, and propagates other integrity failures. Focused unit and HTTP tests prove the overlong-key 400 and non-duplicate 409/no-row paths.
2. The prior report used mismatched S/F meanings and overstated observations. This report uses the fixed matrix above and labels live UI behavior as inferred where it was not manually exercised.
3. The fixed key now traces through the Flutter request callback and Spring header/history assertions. The canonical test also covers K2, authenticated identity preservation, and one matching row. Flutter models a lost response followed by 208/null terminal success with no repeat create call.
4. The appeal path already uses `requestNullableObject`; the global `parseResponse` nullable shortcut was restored to its starting state to keep this change scoped. The nullable 208 parser path remains covered by `parseNullableResponse` tests.
5. User/body namespace risk is recorded below: the existing history uniqueness is global, and the server does not compare a reused key against body/user fingerprints.

## Correction Accounting

- Primary implementation cycle: 1.
- Pre-review corrective cycle 1: renamed the Java record factory that collided with an accessor; compile then passed.
- Pre-review corrective cycle 2: corrected the focused Flutter test's key-factory expectation; the focused test then passed.
- Database fixture calibration: the new canonical test fixture was adjusted to satisfy the observed production-compatible schema (vehicle owner ID, valid offense process state/number, and conditional offense-type seed). This changed test setup, not product behavior.
- Post-review corrective cycles: 1 (this report and the bounded rework above). No further product correction is authorized in this run.

## Residual Risk

- The legacy appeal integration test and full Maven suite remain red because existing fixtures do not satisfy the isolated production-compatible schema and other existing integration contexts. This limits whole-repository regression confidence.
- The Flutter UI lifecycle was verified by automated coordinator tests, analysis/build results, and source inspection, but not by manual browser interaction.
- The existing idempotency schema makes the key globally unique. Cross-user reuse of an identical key is therefore treated as a duplicate; no schema change was in scope.
- The key/body namespace is not fingerprinted: reusing K with a different body or user follows the existing global-key duplicate rule. This is an explicit residual risk, not an observed acceptance failure.
- The response-loss path is modeled by a Flutter transport error followed by a 208 response callback and independently traced through the Spring fixed-key test; no live dropped HTTP response was injected.
- A forced downstream failure after key reservation was not injected. Transaction rollback behavior beyond the observed non-duplicate integrity failure is inferred from the rollback-enabled single transaction.

## Conclusion

The focused server and Flutter acceptance contracts are observed passing. Repository-wide verification is not fully green for the baseline reasons recorded above, so this report does not claim unrestricted project validation or compatibility beyond the commands and environment observed in this run.
