# EXP-005 Change Contract — Client Session-Recovery Classification

Mode: Lightweight (see MODE-SELECTION.md). One bounded change.
Base: experiment/looppilot-final-assignment-exp-005 @ main ba3b49d8.

## Objective

在保持现有登录、登出、rotation 与 401 恢复行为兼容的前提下，让 Flutter 会话
恢复对 Spring refresh 契约的消费区分「终局拒绝」与「瞬时失败」：瞬时的
429/5xx/超时/网络错误不得销毁一个 access token 仍然有效的会话，也不得在
主动续期路径中删除仍被服务端承认的 refresh token。

Gap being fixed: A-G1 (FINAL-ASSIGNMENT-CROSS-LAYER-AUDIT.md), plus the A-G3
Flutter characterization-test gap for the behaviors this change touches.

## Spring contract (CONSUMED, not modified — pinned by new tests)

- POST /api/auth/refresh: valid token → 200 `{success:true, data:{accessToken,
  refreshToken, expiresIn}}` (rotation pair); invalid/rotated/garbage token →
  401 ApiResponse `{success:false, ...}` via BadCredentialsException →
  GlobalExceptionHandler (TERMINAL signal). Missing body field → 400
  (validation, TERMINAL).
- POST /api/auth/login under throttle: 429 + `Retry-After` header +
  `{success:false, errorCode:LOGIN_RATE_LIMITED, message, retryAfterSeconds}`
  (TRANSIENT-class signal shape; LoginAttemptGuard).
- Refresh endpoint is NOT governed by LoginAttemptGuard (login-only); a 429
  at refresh can only originate from infrastructure — still TRANSIENT.

## Flutter contract (MODIFIED)

`AuthService` (final_assignment_front/lib/core/auth/auth_service.dart) —
single product file:

1. New internal outcome classification for one refresh attempt:
   - `success` — 200 with parsable access token; rotation persisted (unchanged).
   - `rejected` (terminal) — HTTP 400/401/403; or no stored refresh token.
     Existing 404 Cloud-auth special case keeps its current inline behavior
     and classifies as rejected.
   - `transient` — HTTP 408/429/5xx; request timeout; network/socket errors;
     response parse failures (200 without a usable token).
2. `ensureValidSession` mapping:
   - success → valid (unchanged).
   - rejected → clearTokens once + optional redirect (unchanged behavior).
   - transient + current access token NOT hard-expired → session remains
     valid; NO token clearing; return true.
   - transient + access token hard-expired → return false WITHOUT clearing
     stored tokens (refresh token preserved for later recovery); redirect
     only when requested (clearStoredTokens: false).
3. `refreshJwtToken(): Future<bool>` public signature and single-flight
   semantics preserved (true only for `success`). Callers in api_client.dart
   are NOT modified.

## Security invariants

- No token value is ever logged, stored anywhere new, or transported anywhere
  new by this change.
- Terminal rejection (server explicitly refuses the refresh token) still
  destroys local session state exactly as before — no weakening of cleanup.
- Blacklist, logout, storage (secure-storage/web-memory), redirect-guard and
  single-flight behaviors are untouched and pinned by new characterization
  tests.
- The change must not create a retry loop: transient classification performs
  NO automatic re-attempt; the next attempt happens at the next caller-driven
  ensureValidSession.

## Error/retry contract

Terminal = 400/401/403/404(+missing refresh token). Transient = 408/429/5xx/
timeout/network/parse. Retry policy: passive (next call), never automatic.
Login-side 429 UX (Retry-After surfacing, A-G2) is explicitly OUT of scope
and recorded as residual.

## Included scope

- final_assignment_front/lib/core/auth/auth_service.dart (product)
- final_assignment_front/test/core/auth/auth_service_session_recovery_test.dart (new)
- finalAssignmentBackend/src/test/java/.../integration/auth/
  SessionRecoveryContractIntegrationTest.java (new, characterization; name
  matches the Surefire include list so it actually runs)
- finalAssignmentBackend/src/test/java/.../integration/auth/
  LoginThrottleContractIntegrationTest.java (new, characterization of the 429
  transient-signal shape, isolated context with tight guard limits via test
  properties so it cannot pollute the shared-context IP budget)

## Excluded scope (recorded residuals, no implementation)

- api_client.dart reactive-401 path (`_clearSessionAndRedirect` after a real
  401 + failed refresh) — Case-2 residual: a background call racing a
  hard-expired token during a transient outage can still clear tokens.
- login.dart 429 Retry-After UX (A-G2); B/C/D/E candidate gaps; Spring
  product code; other backends; React frontend; dependency changes.

## RED/GREEN protocol

Flutter behavior tests are written FIRST and observed failing against the
current code (true RED) for the transient cases; characterization tests for
preserved behaviors are expected green before and after. Spring tests are
pure characterization (expected green; recorded as such — per protocol this
confirms existing server behavior is correct and needs no server change).
No code is broken deliberately to manufacture RED.

## Acceptance (Lightweight closure)

1. New Flutter tests: transient-preserves-session (429, network, 5xx-expired),
   terminal-clears-once, single-flight, rotation-persistence,
   logout-cleanup-on-API-failure — all green after the change.
2. Spring characterization classes green when run standalone
   (-Dtest=SessionRecoveryContractIntegrationTest / LoginThrottleContract…).
3. flutter analyze no new issues; dart format clean on touched files;
   mvn compile/package green; full `mvn test` and full-suite deltas reported
   honestly against the pre-existing red baseline.
4. Spec + Standards + Security review pass; findings (if any) registered in
   REVIEW.md before rework.
5. No secret, no build artifact, no dependency change in the diff.

## Rollback

Single revert of the product file + test files; no data, schema, config, or
server impact.
