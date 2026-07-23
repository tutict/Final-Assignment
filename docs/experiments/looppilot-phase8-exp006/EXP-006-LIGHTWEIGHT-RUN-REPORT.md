# EXP-006 Lightweight Run Report

## Run identity

- Mode: Lightweight
- Branch: `experiment/looppilot-final-assignment-exp-006-lightweight`
- Baseline: `ba3b49d83e1f73aeab8392fd5a5292d6961b058e`
- Scope: authenticated `POST /api/appeals` idempotent retry across Spring and Flutter
- Database configured for integration verification: `traffic_exp006_lightweight`
- Pre-review correction cycles used: 2 of 2
- Post-review correction cycles used: 0 of 1
- Hard trigger or escalation: none
- Final independent review: pending after the frozen commit

## Implemented behavior

The Spring path now claims an appeal-creation idempotency record before the business
write. The claim is scoped by idempotency key and authenticated user, a failed claim
may be reopened, and an already pending or successful claim returns HTTP 208 with a
successful `ApiResponse` whose `data` is null. Appeal creation and the success state
transition execute in the controller transaction.

The Flutter API accepts the nullable HTTP 208 response. An appeal creation operation
reuses one pending Future and one key, retains the key after transient failures,
releases it after success or terminal failure, and can release a retained key when
cancelled. The appeal dialog closes only after a successful result.

No database schema, dependency, authentication, unrelated feature, release, or
deployment change was made.

## Observed evidence

| Command | Observed result |
| --- | --- |
| `mvn -DskipTests compile` | Passed; Maven reported BUILD SUCCESS. |
| `mvn -Dtest=AppealRecordApplicationServiceTest test` | Passed: 20 tests, 0 failures, 0 errors, 0 skipped. |
| `mvn -Dtest=AppealCreationIdempotencyContractTest test` | Passed: 1 test, 0 failures, 0 errors, 0 skipped. The controller fixture observed first-create HTTP 201/non-null data, same-key duplicate HTTP 208/success/null data, one business create call, one success transition, and authenticated identity propagation. |
| `mvn -Dtest=AppealIntegrationTest test` | Failed before appeal creation in all 8 tests. Vehicle setup returned HTTP 409 because the configured database requires `vehicle_information.owner_id_card`, while the existing fixture omits it. |
| `mvn test` | Failed in the integration portion. The appeal integration tests hit the same vehicle-fixture/schema mismatch; other integration suites also observed HTTP 429 rate-limiter contamination and some HTTP 409 setup failures. Focused unit and contract tests passed within this run. |
| `mvn -DskipTests package` | Passed; Maven reported BUILD SUCCESS and produced the backend package with tests skipped. |
| `dart format --output=none --set-exit-if-changed lib test` | Failed because three unrelated existing files would be reformatted: `field_validation_error.dart`, `user_management_controller_api.dart`, and `profile_tile.dart`. The check did not modify them. |
| `flutter analyze` | Failed on one unrelated existing warning: unused local variable `newDecodedToken` in `vehicle_list.dart:107`. No analyzer issue was reported for changed files. |
| `flutter test test/features/appeal/appeal_creation_contract_test.dart` | Passed: 5 tests. |
| `flutter test` | Passed: 15 tests. |
| `flutter build web --release` | Passed; release Web output was built and the Wasm dry run succeeded. |
| `git diff --check` | Passed; only line-ending conversion warnings were printed. |

Focused Flutter tests directly observed that the retry key is sent as the
`Idempotency-Key` header, an authenticated 208/null response is accepted without a
type error, concurrent submission shares the same Future, transient failure retains
the key, terminal failure releases it, duplicate success releases it, a new operation
uses a new key, and cancellation releases a retained key.

Focused Spring tests directly observed the application service passing the fixed
cross-layer fixture key `appeal-cross-layer-key` into the request-history claim with
the authenticated user ID. The Flutter fixture used the same literal key and observed
it in the outgoing header. This is fixture-level cross-layer evidence; it is not a
database row-count observation.

## Acceptance evidence status

- Observed in focused tests: same-key duplicate controller response semantics;
  nullable Flutter parsing; pending-call reuse; key retention after transient failure;
  key release after success, terminal failure, and cancellation; new-key behavior for
  a new operation; authenticated identity propagation into the idempotency claim.
- Inferred from the reviewed implementation and focused tests: the insert-if-absent
  claim plus failed-state compare-and-set prevents the same authenticated user and key
  from starting more than one non-failed business operation.
- Expected but not observed against the configured database: exactly one appeal row
  and one request-history row after first request, response loss, and same-key retry;
  failed-key reopening in a real transaction; and complete compatibility with existing
  appeal integration behavior.
- Unverified: database-backed S1, S5, S7, and full-regression S8 acceptance evidence.
  The prerequisite fixture/schema incident prevented the database path from reaching
  the appeal endpoint, and the whole Spring suite was not green.

## Execution infrastructure incidents

The configured integration database schema and the repository vehicle fixture are
not aligned: `vehicle_information.owner_id_card` is mandatory in the database but is
not populated by the existing fixture. This caused the focused appeal integration
suite to fail during setup, before the changed endpoint executed. The whole Spring
suite additionally encountered shared rate-limiter state (HTTP 429) and other setup
conflicts. These outcomes are recorded as execution-infrastructure evidence, not as
product passes or protocol findings.

An initial Maven invocation also encountered a transient GraalPy environment problem
(`pip` unavailable). Later Maven compile, focused tests, and package commands processed
that step successfully without repository configuration changes.

## Residual risks

- The database-backed single-row invariant remains unverified in this run.
- The exact response-loss retry scenario remains unverified end to end.
- Full Spring regression is not green in the observed environment.
- Independent Standards and Spec review must occur against the frozen commit before
  any approval or integration claim.

This report does not authorize or claim a pull request, merge, release, deployment,
migration, or traffic change.
