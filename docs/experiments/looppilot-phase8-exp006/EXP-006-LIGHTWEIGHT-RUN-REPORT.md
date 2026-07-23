# EXP-006 Lightweight Run Report

## Run identity

- Mode: Lightweight
- Branch: `experiment/looppilot-final-assignment-exp-006-lightweight`
- Baseline: `ba3b49d83e1f73aeab8392fd5a5292d6961b058e`
- Scope: authenticated `POST /api/appeals` idempotent retry across Spring and Flutter
- Database configured for integration verification: `traffic_exp006_lightweight`
- Pre-review correction cycles used: 2 of 2
- Post-review correction cycles used: 1 of 1
- Hard trigger or escalation: none
- Initial independent review: Standards FAIL and Spec FAIL
- Rework review: pending against the new frozen commit

## Implemented behavior

The Spring application service now owns the transaction and the complete
claim/create/success decision. It returns an explicit `CREATED`, `DUPLICATE`, or
`COLLISION` result. The controller is limited to authentication context, request
mapping and validation, and protocol response adaptation; it has no transaction and
does not directly create the appeal or update request history.

The claim is user-aware without a schema change. An existing key owned by another
authenticated user returns HTTP 409 `IDEMPOTENCY_KEY_COLLISION`; it does not return a
false HTTP 208 and cannot reopen the other user's failed claim. A same-user failed
claim may be reopened, while a pending or successful same-user claim is a duplicate.

The Flutter API accepts the nullable HTTP 208 response. An appeal creation operation
reuses one pending Future and one key, retains the key after transient failures,
releases it after success or terminal failure, and releases it after cancellation.
Every appeal-dialog route completion, including action, barrier, system back, and a
pending request that completes after dismissal, passes through the same cleanup path.

No database schema, dependency, authentication, unrelated feature, release, or
deployment change was made.

## Observed evidence

| Command | Observed result |
| --- | --- |
| `mvn -DskipTests compile` | Passed after rework; Maven reported BUILD SUCCESS. |
| `mvn "-Dtest=AppealRecordApplicationServiceTest,AppealCreationIdempotencyContractTest" test` | Passed after rework: 23 tests, 0 failures, 0 errors, 0 skipped. This comprised 21 application/idempotency tests and 2 controller contract tests. |
| `mvn -Dtest=AppealIntegrationTest test` | Failed before appeal creation in all 8 tests. Vehicle setup now passed, but offense setup returned HTTP 409 because the fixture value `processStatus=Pending` is not accepted by the configured database enum (`Data truncated for column 'process_status'`). |
| `mvn test` | Not rerun after rework because the focused integration prerequisite remained blocked. The pre-review whole-suite run had already failed in integration setup and also observed shared HTTP 429 rate-limiter contamination. |
| `mvn -DskipTests package` | Passed; Maven reported BUILD SUCCESS and produced the backend package with tests skipped. |
| `dart format --output=none --set-exit-if-changed lib test` | Failed because three unrelated existing files would be reformatted: `field_validation_error.dart`, `user_management_controller_api.dart`, and `profile_tile.dart`. The check did not modify them. |
| `flutter analyze` | Failed on one unrelated existing warning: unused local variable `newDecodedToken` in `vehicle_list.dart:107`. No analyzer issue was reported for changed files. |
| `flutter test test/features/appeal/appeal_creation_contract_test.dart` | Passed after rework: 7 tests, including two widget dismissal tests. |
| `flutter test` | Passed after rework: 17 tests. |
| `flutter build web --release` | Passed; release Web output was built and the Wasm dry run succeeded. |
| `git diff --check` | Passed; only line-ending conversion warnings were printed. |

Focused Flutter tests directly observed that the retry key is sent as the
`Idempotency-Key` header, an authenticated 208/null response is accepted without a
type error, concurrent submission shares the same Future, transient failure retains
the key, terminal failure releases it, duplicate success releases it, a new operation
uses a new key, and cancellation releases a retained key. Widget tests observed both
barrier dismissal while a request was pending (cleanup completed when that request
later failed) and system-back dismissal of a retained transient key.

Focused Spring tests directly observed the application service owning the
claim/create/success decision and passing the fixed cross-layer fixture key
`appeal-cross-layer-key` into request-history claim data with the authenticated user
ID. They also observed that another user's failed history returns `COLLISION` without
calling reopen. Controller tests observed 201/208 adaptation and a different user's
409 collision response.

The Flutter trace used the same literal `appeal-cross-layer-key` on both attempts and
observed it in both outgoing headers. Its first attempt raises a modeled transport
read failure and the retry accepts 208/null. This is explicitly modeled
response-read-loss evidence, not proof of a live HTTP response being dropped.

The Spring integration test contains the same fixed-key trace, discards the first
response before retry, and asserts one appeal row and one request-history row. That
trace did not execute because offense setup failed first. Therefore the shared fixture
is observed in focused Spring/Flutter tests, while its database row-count portion is
unverified.

## Acceptance evidence status

- Observed in focused tests (fixed mapping): S2, S3, S4, S6, and F1-F9. Evidence
  includes same-key duplicate controller response semantics, user collision handling,
  nullable Flutter parsing, pending-call reuse, transient retention, release on
  success/terminal/cancel/dismissal, new-operation key behavior, and authenticated
  identity propagation into the claim.
- Inferred from implementation plus focused tests: the insert-if-absent claim,
  user-qualified failed-state compare-and-set, and user-qualified success transition
  prevent a different authenticated user from reopening or completing the key.
- Expected but not observed against the configured database: exactly one appeal row
  and one request-history row after first request, modeled response read loss, and
  same-key retry;
  failed-key reopening in a real transaction; and complete compatibility with existing
  appeal integration behavior.
- Unverified (fixed mapping): database-backed S1, S5, S7, and full-regression S8.
  The current prerequisite fixture/database mismatch prevented the database path from
  reaching the appeal endpoint. Modeled read-loss evidence does not promote S5 to a
  live end-to-end observation.

## Execution infrastructure incidents

The earlier vehicle fixture blocker was corrected in the scoped appeal integration
fixture by supplying the fields required by the configured database. The current
observed blocker is the next prerequisite: offense creation attempts to store fixture
`processStatus=Pending`, which the configured database enum rejects. All 8 appeal
integration tests consequently failed in `@BeforeEach` before the changed endpoint
executed. This supersedes the stale vehicle-blocker statement; it does not establish a
database-backed product pass.

The pre-review whole Spring suite additionally encountered shared rate-limiter state
(HTTP 429) and other setup conflicts. These outcomes are recorded as execution
infrastructure incidents, not as Product or Protocol Findings.

An initial Maven invocation also encountered a transient GraalPy environment problem
(`pip` unavailable). Later Maven compile, focused tests, and package commands processed
that step successfully without repository configuration changes.

## Residual risks

- The database-backed single-row invariant remains unverified in this run.
- A modeled response-read-loss retry passed in Flutter, but a live dropped-response
  retry and the database half of that trace remain unverified.
- Full Spring regression was not rerun after rework and is not green in the observed
  environment.
- Independent Standards and Spec re-review must occur against the new frozen commit
  before any approval or integration claim.

This report does not authorize or claim a pull request, merge, release, deployment,
migration, or traffic change.
