# TASK-001 Delivery: Fixed Appeal Idempotency Contract Characterization

## Scope and evidence labels

This delivery characterizes only the Spring `POST /api/appeals` path and the
Flutter user appeal creation path in this worktree. `Observed` means directly
present in the cited source. `Inferred` means a consequence of those observed
boundaries that was not executed. `Expected` describes the fixed contract.
`Unverified` means the current tests or this read-only Task did not establish the
claim.

## Spring criteria

| Criterion | Current boundary and status | Minimal implementation/test surface or unknown |
|---|---|---|
| S-1 | **Partial, observed.** The authenticated controller accepts an optional `Idempotency-Key`, registers it, inserts an appeal, marks history success, then returns 201 (`AppealManagementController.java:71-102`). Registration inserts a `PROCESSING` history row (`AppealIdempotencyService.java:28-34,79-85`); the appeal insert is separate (`AppealRecordApplicationService.java:133-157`). The database has a unique key on `sys_request_history.idempotency_key` (`database/traffic.sql:832-850`). **Unverified:** exactly one appeal plus exactly one history row is not asserted by the existing integration test. **Inferred risk:** registration also schedules a create Kafka event before the direct create finishes (`AppealRecordApplicationService.java:133-145`; `AppealRecordEventPublisher.java:29-53`); the consumer can itself insert a create payload while history is `SUCCESS/PENDING`, because only `SUCCESS/DONE` skips (`AppealRecordKafkaListener.java:32-75`; `AppealBusinessPolicy.java:15-19`). | Backend implementation ownership: `AppealManagementController.java`, `AppealRecordApplicationService.java`, `AppealIdempotencyService.java`, and, only if the duplicate create race is removed there, `AppealRecordKafkaListener.java`/publisher. Test ownership: extend `AppealIntegrationTest.java` with direct appeal/history row counts. Do not require a schema redesign; the unique key already exists. |
| S-2 | **Partial, observed.** A completed `SUCCESS/DONE` key is skipped and returns HTTP 208 (`AppealManagementController.java:90-100`; `AppealBusinessPolicy.java:15-19`). The existing integration test repeats the same body/key and asserts 208 plus `success=true` (`AppealIntegrationTest.java:78-94`). **Unverified:** it does not count appeal or history rows, compare the prior outcome, or bind the key to user/body. | Add a fixture that records the first appeal ID, repeats authenticated user/body/K, asserts 208, and queries both tables for counts and stored business ID. |
| S-3 | **Observed, satisfied at the Spring response boundary.** The duplicate branch uses `ApiResponse.ok(null)` (`AppealManagementController.java:92-95`), and `ok` sets `success=true` while error sets `success=false` (`ApiResponse.java:15-27`). The current test asserts the success flag (`AppealIntegrationTest.java:89-93`). | Preserve this response shape or introduce an explicit duplicate-success payload; add assertions for `success`, `errorCode`, `message`, and nullable `data` together so no contradictory failure state can regress. |
| S-4 | **Inferred, unverified.** Lookup and uniqueness use the key value (`AppealIdempotencyService.java:28-34`; `SysRequestHistoryMapper.java:13-14`), so absent K2 proceeds to a new history insert and appeal create. No current appeal test submits the same body with K2 and counts two operations. | Extend the same integration fixture with K2 and assert a second appeal/history operation. |
| S-5 | **Partial.** **Expected:** response loss after a committed success followed by K must replay/return duplicate success without another insert. **Inferred:** once history is `SUCCESS/DONE`, retry skips. **Unverified:** response loss is not modeled, and there are separate transaction/commit windows between history registration, direct insert, and final history update (`AppealRecordService.java:30-39,128-137`; `AppealManagementController.java:90-105`). | Add a modeled response-loss test and label it modeled. It must observe a committed first insert/history outcome, retry K, and assert one appeal row. Implementation should make the durable success/outcome boundary explicit before response emission. |
| S-6 | **Partial, observed.** Method security requires an authenticated role; `createdBy`/`updatedBy` come from `Authentication`, and a regular user's `driverId` is overwritten from the authenticated profile (`AppealManagementController.java:71-89`). However the request accepts `driverId` and appellant name/ID/contact (`AppealCreateRequest.java:14-37`), and the mapper copies them (`AppealRecordRequestMapper.java:17-25`). Request history stores no user, endpoint, body fingerprint, or operation type in this path (`AppealIdempotencyService.java:79-85`), and key lookup is global (`SysRequestHistoryMapper.java:13-14`). | Backend implementation/tests should preserve server-derived username and regular-user driver ownership, reject/ignore conflicting client identity fields as the agreed contract requires, and test a forged `driverId`. Whether appellant personal fields must also be server-derived is **unverified** and requires Supervisor/spec disposition. |
| S-7 | **Unverified.** The current duplicate integration test asserts only statuses/body (`AppealIntegrationTest.java:78-94`). The direct-create/Kafka timing described under S-1 means one matching appeal row cannot be claimed from source alone. | Same backend integration fixture as S-1/S-2: query by returned appeal ID/business ID and stable matching attributes, assert exactly one non-deleted appeal row after duplicate processing settles. |
| S-8 | **Partial, observed coverage only.** Existing integration coverage exercises validation, approval/rejection, concurrent workflow transition, and Kafka convergence (`AppealIntegrationTest.java:44-75,96-210`). The create defaults/validation/insert path remains in `AppealRecordApplicationService.java:148-178`. | Run the existing appeal integration suite unchanged after the focused idempotency tests. Preserve endpoint, 201 first-create shape, validation, authorization, defaults, workflow, and read behavior. Runtime compatibility remains **unverified** in this characterization Task. |

## Flutter criteria

| Criterion | Current boundary and status | Minimal implementation/test surface or unknown |
|---|---|---|
| F-1 | **Not satisfied for transient failures.** The dialog generates a key immediately before each submit and passes it through the API (`user_appeal.dart:682-701`; `appeal_management_controller_api.dart:17-28`). The network layer preserves headers/body only for its one built-in 401 refresh retry (`api_client.dart:214-231`). Timeout/client errors are rethrown, not retried (`api_client.dart:246-255`), and reopening/resubmitting generates a new key. | Frontend implementation ownership: an appeal-operation state seam in `user_appeal.dart` (or a small new focused controller) that owns body+key across transient retry. Test with a fake API: fail transiently, retry, assert identical key and body. |
| F-2 | **Not reliably satisfied.** A local `isSubmitting` flag is checked by the button and set before awaiting (`user_appeal.dart:662-703`), but the dialog is built on a separate route and the callback calls the page State's `setState`; no dialog-local `StatefulBuilder`/operation state is present (`user_appeal.dart:427-466`). **Inferred risk:** the displayed button callback may remain enabled and a second tap can issue another call. | Widget/operation test with a pending fake completer and two taps must assert one call and one key. Give the dialog an actually rebuilding pending state and guard the submit handler itself. |
| F-3 | **Observed defect.** HTTP 208 is classified as success (`base_api_client.dart:29-35,534-564`), but non-nullable object parsing returns `null as T` (`base_api_client.dart:578-586`). `createAppeal` declares `Future<AppealRecordModel>` (`appeal_management_controller_api.dart:17-28`), so duplicate success can become a runtime type error. | `base_api_client.dart` plus focused parser tests for 208/`{"success":true,"data":null}`. The appeal API may need an explicit nullable/result type; do not silently fake an `AppealRecordModel`. |
| F-4 | **Not satisfied.** Because F-3 throws, `_submitAppeal` catches duplicate success and displays failure (`user_appeal.dart:412-424`). | API/UI test: 208 nullable success produces a successful or recoverable terminal result and never an error toast. |
| F-5 | **Observed but not distinguished from retry.** Each submit-button execution calls `generateIdempotencyKey()` (`user_appeal.dart:696-701`; generator at `base_api_client.dart:85-95`). Thus a genuinely new operation gets a new key, but so does a retry after the dialog closes. | Operation-state tests must separately assert reuse for retry and rotation only after terminal success/cancel/validation release. |
| F-6 | **Partial, implicit.** Local validation resets `isSubmitting` before any key is created (`user_appeal.dart:676-680,696-703`); cancel closes before key creation (`user_appeal.dart:653-660`). API errors are swallowed and the dialog is closed, so all failures currently discard state rather than classify terminal validation versus transient failure (`user_appeal.dart:412-424,700-705`). | Add explicit error classification tests. Cancel and terminal validation release state/key; transient errors must not. |
| F-7 | **Not satisfied.** `_submitAppeal` catches and returns normally on every error (`user_appeal.dart:412-424`), after which the caller resets state and closes the dialog (`user_appeal.dart:700-705`); the local key is lost. | Same operation seam/test as F-1, using timeout/network exceptions. |
| F-8 | **Implicitly satisfied, unverified.** Success is followed by refresh/toast, then caller reset and dialog close (`user_appeal.dart:412-420,700-705`), which discards the local key. There is no explicit operation object whose release can be asserted. | Test success clears pending operation/key and a subsequent operation generates K2. |
| F-9 | **Not satisfied.** HTTP 208 reaches `null as T` and then the failure catch (F-3/F-4). It makes no automatic repeat, but it is not a successful terminal outcome. | Parser plus widget/operation test: one call, duplicate-success terminal state, no failure UI, operation/key cleared. |

## Non-overlapping implementation and test ownership

- Backend Task: own only the Spring create/idempotency orchestration files listed
  under S-1 and `AppealIntegrationTest.java` (plus a narrowly focused unit test if
  needed). Do not edit Flutter files.
- Frontend Task: own `base_api_client.dart`,
  `appeal_management_controller_api.dart` only if its return contract changes,
  `user_appeal.dart` or one new appeal-operation helper, and focused Dart tests.
  Do not edit Spring files.
- Integration/verification Task: own a cross-layer fixture or harness, not either
  core implementation. Assert Flutter operation key = Spring header = one
  `sys_request_history.idempotency_key` = retry key, with exactly one matching
  appeal row. A response-loss case may be injected, but its result must be labelled
  **modeled**, not observed production behavior.

## Remaining unknowns

- **Unverified:** whether the running Spring/Kafka configuration actually realizes
  the inferred double-create timing window; source boundaries make it a required
  test, not an observed runtime failure.
- **Unverified:** desired replay payload for HTTP 208 (nullable success marker versus
  stored `AppealResponse`). The fixed criteria require successful/recoverable
  handling but do not require a non-null appeal body.
- **Unverified:** whether S-6 requires all appellant personal fields to be sourced
  from the authenticated profile, or only username/driver ownership. Current code
  guarantees the latter for regular users but accepts the former from the request.
- **Unverified:** platform-specific Flutter behavior was not executed; this Task is
  source characterization only.
