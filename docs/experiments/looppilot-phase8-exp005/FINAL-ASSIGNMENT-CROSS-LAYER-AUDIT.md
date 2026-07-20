# EXP-005 Final-Assignment Cross-Layer Contract Audit

Date: 2026-07-20. Sources: five delegated read-only auditors (A–E) plus
Supervisor first-hand verification of every load-bearing claim cited below.
Citations are file:line at main @ ba3b49d8. Evidence labels: [V] = verified
first-hand or by auditor with code citation; [S] = suspected, unverified;
[O] = overturned (looked broken, is handled).

## Audited mainline boundary

Spring: `finalAssignmentBackend` (Spring Boot 4.0.1, Java 25, Spring Security
+ JWT, MyBatis-Plus/MySQL, Redis/Caffeine, Kafka, ES, Vert.x WebSocket).
Flutter: `final_assignment_front` (Flutter 3.44.4/Dart 3.12.2, GetX, http,
flutter_secure_storage, jwt_decoder, web_socket_channel).
Explicitly excluded (read-only background only): finalAssignmentCloud,
final_assignment_backend_go, final_assignment_backend_quarkus,
final_assignment_front_react.

## API contract map (auth-centric, verified)

| Endpoint | Response contract | Flutter consumer |
| --- | --- | --- |
| POST /api/auth/login | 200 raw Map: top-level accessToken (+legacy jwtToken alias), refreshToken, authUserId, roles; 401 `{success:false,errorCode:UNAUTHORIZED,message}`; 429 `{success:false,errorCode:LOGIN_RATE_LIMITED,message,retryAfterSeconds}` + Retry-After header (AuthController.java:87-125) | login.dart `_authUser`; 429 → static message, retryAfterSeconds ignored (login.dart:331) |
| POST /api/auth/refresh | 200 `ApiResponse<TokenResponse>` `{success,data:{accessToken,refreshToken,expiresIn}}`; invalid/rotated token → BadCredentialsException → 401 ApiResponse (AuthWsService.java:178-195; exception/global/GlobalExceptionHandler.java:72-76) | auth_service.dart `_refreshJwtTokenInternal` (dual-shape tolerant parse, rotation persisted, auth_service.dart:177-191) |
| POST /api/auth/logout | `ApiResponse<Void>`; blacklists access token, deletes refresh rows | auth_service.dart logout() — clears local state in `finally` even on API failure |
| GET /api/auth/me | `ApiResponse<UserProfileResponse>` (no password/salt) | UserProfileService |
| POST /api/ws-ticket | `ApiResponse<{ticket,expiresAt}>`, requires authenticated (blacklist enforced in JWT filter first) | business_event_listener.dart (fresh ticket per connect, first-frame transport) |
| JWT filter errors | 401 ApiResponse with distinct errorCodes TOKEN_EXPIRED / TOKEN_INVALID / TOKEN_REVOKED / UNAUTHENTICATED | exception_mapper.dart / base_api_client.dart fallback chain |

Client 401-recovery path (Supervisor-verified; corrects an auditor citation
that pointed at interceptor.dart, which is actually a request-logging
wrapper): `api_client.dart:214-239` — on 401 (bearerAuth, not a retry):
single-flight `_safeRefreshToken()` (static completer, api_client.dart:285-313)
→ on success replay request exactly once (`isRetry: true`); on failure
`_clearSessionAndRedirect()`. Additionally `invokeAPI` calls
`ensureValidSession(redirectIfInvalid: true)` before EVERY authenticated
request (api_client.dart:173, 322-326) — this makes AuthService's refresh
outcome handling app-wide in blast radius.

## Candidate A — Authentication & session lifecycle

Spring side hardened (commit ba3b49d8) and richly integration-tested
(AuthIntegrationTest: 11 tests incl. rotation invalidation, blacklist,
concurrent-refresh single-success, 403-no-redirect, /me sanitization).

[O] Overturned suspicions: concurrent-401 refresh stampede (single-flight
exists, auth_service.dart:124-147 + api_client.dart:285-313); blacklisted
token obtaining WS ticket (filter blocks first); logout API failure stranding
local session (finally-cleanup, auth_service.dart:288-291); rotation not
persisted (persisted, :188-191); web token storage ambiguity (explicit
memory-only + regression test); 403 forcing logout (handleForbidden logs
only, :204-208); duplicate redirect (guarded, :221-240); tokens in logs/URLs
(regression-tested).

[V] **A-G1 (selected gap)**: `_refreshJwtTokenInternal` collapses every
non-200 refresh outcome into terminal `false` (auth_service.dart:172-175);
`ensureValidSession` then destroys the session — clearTokens + redirect
(auth_service.dart:59-70). Because `invokeAPI` runs `ensureValidSession`
before every authenticated call, one transient refresh failure (429 throttle,
5xx, timeout, network blip) while the access token is inside the 5-minute
proactive-refresh window — i.e. typically STILL VALID — logs the user out and
deletes a refresh token the server still honors. The backend's own suite
asserts the opposite server-side invariant ("并发 Refresh…不踢用户下线",
AuthIntegrationTest order-11). Client-side classification terminal-vs-
transient does not exist.
[V] **A-G2**: login 429 contract data (retryAfterSeconds body field,
Retry-After header) unused by Flutter (login.dart:331-332).
[V] **A-G3**: zero Flutter tests cover AuthService session behavior
(single-flight, 401-once, cleanup-once, transient handling). Flutter test
inventory is 3 files (SSE parser, token security statics, widget smoke).
[S] AuthTokenStore read failure inside ensureValidSession's catch would clear
tokens like a malformed JWT (not traced end-to-end; recorded, not exercised).

## Candidate B — Idempotent writes & duplicate submission

NOTE ON EVIDENCE PROVENANCE: auditor B produced a preliminary summary and a
final deep report whose conclusions materially diverged. The preliminary
asserted an appeal "domain-fingerprint dedup" and a "user-scoped, 24h TTL"
request history — the Supervisor re-verified the cited code first-hand and
found NEITHER exists. The deep report's citations were confirmed line-by-line
and are authoritative below. Recorded as Worker-reliability evidence.

[V] Server mechanism: `sys_request_history` with `UNIQUE KEY
uk_idempotency_key` — **globally key-unique, NOT user-scoped** (user_id column
nullable, never populated by the appeal path; database/traffic.sql:850), **no
TTL/purge job**. `AppealBusinessPolicy.isDuplicateRequest(history) = history
!= null` (AppealBusinessPolicy.java:12-14): ANY pre-existing key — including
a FAILED attempt — triggers `RuntimeException("Duplicate appeal request
detected")` → GlobalExceptionHandler catch-all → **500 INTERNAL_ERROR** (a
FAILED key can never be retried with the same key). Duplicate-COMPLETED →
208 with `ApiResponse.ok(null)` — replay body carries NO business id.
Payment: any existing key → 208 even when the recorded attempt FAILED
(businessStatus ignored) — a false "already done" can mask a failed payment.
RAG document submissions carry no idempotency protection at all.
[V] **B-G1**: Flutter regenerates the idempotency key per user attempt, and
several sites use `DateTime.now().millisecondsSinceEpoch.toString()` as the
key (user_appeal.dart:31-33 — verified first-hand) — collision-prone across
users given the global key-only unique index, and never reused across
user-initiated retries (retry after timeout = new key = fresh request =
**second record**; no natural unique constraint on appeals).
[V] **B-G2**: when dedup DOES fire, the 208 success signal crashes the
client: `parseResponse` executes `return null as T` on 208
(base_api_client.dart:584-586, Supervisor-verified) — TypeError for
non-nullable T (appeal/vehicle/payment creation all use `requestObject`) —
so "already processed" is DISPLAYED AS FAILURE, inviting a fresh-key
resubmit that then succeeds and creates the duplicate.
[V] B-G3: duplicate-status envelope inconsistent (208-null / 500 / 409 /
register raw `{error}`); Flutter maps errorCode `DUPLICATE_REQUEST` that the
backend never emits (dead contract). Zero Flutter idempotency tests.
[O] Overturned: automatic client retry storm (none exists — no auto-retry of
mutations); "401-refresh retry regenerates the key" (it correctly REUSES the
original header, api_client.dart:220-231); workflow-event replay duplication
(state machine no-ops → 409); register duplicate (username natural key,
race-safe same-key replay); payment create race (unique index + exception
catch is race-safe).

## Candidate C — Driver-scoped authorization & error projection

PROVENANCE: as with Candidate B, the deep report revised the preliminary
summary; Supervisor spot-verified the load-bearing citations. Notably the
preliminary claimed a central `DriverAccessGuard` bean and existing
"cross-user 403" tests — neither exists.

[V] Enforcement architecture: NO central guard — a copy-pasted private
`canAccessDriver()` helper per controller (fine/offense/deduction/driver/
vehicle/payment; the AppealManagementController copy at :428-438 is dead
code). Ownership IS re-derived server-side from the authenticated principal
on every USER-reachable driver-scoped endpoint audited; client driverId is
addressing-only. Role normalization (ROLE_ prefix) consistent on both sides.
[V] C-G1: 403 rendered as empty data on the user progress page — which calls
an admin-only endpoint (`/api/progress` is @RolesAllowed SUPER_ADMIN/ADMIN),
so USER always 403s and sees "暂无…" (online_processing_progress.dart:26-51).
[V] C-G2 (process): security-relevant plain `*Test` classes (method-security,
role normalization) are never executed by `mvn test` (Surefire include
drift), and — reversing the preliminary claim — there are ZERO cross-user
ownership integration tests anywhere: the core "USER cannot read another
driver's data" invariant is enforced in code but untested.
[V] C-G3 (new, security-grade): vehicle PUT/DELETE check existence before
ownership → 404-vs-403 difference lets a USER enumerate valid vehicle ids
(VehicleInformationController.java:115-120,144-149); and
`GET /api/vehicles/exists/{licensePlate}` gives any authenticated USER an
unscoped license-plate existence oracle (:583-597). Rejection style is also
inconsistent (empty-body 403 on vehicle PUT/DELETE vs ApiResponse elsewhere).
[V] C-G4: `pushToUser(blank)` falls back to broadcasting business events
(ids+status, no PII) to all connected users (NetWorkHandler.java:308-325);
one FE route (`PUT /api/drivers/{id}/{field}`) has no backend counterpart.
[O] Overturned: backend trusting client driverId (never); 404 existence leak
for driver-scoped READS (ownership-before-existence there); ROLE_ prefix
mismatch; spoofable appeal driverId (overwritten server-side); global
autocomplete leaks (force-scoped for USER).

## Candidate D — WebSocket ticket & realtime session

[V] Ticket: SecureRandom 32-byte, Caffeine TTL 30s, strictly one-time consume,
user-bound, first-frame transport (never URL); blacklisted tokens cannot mint
tickets. Client: fresh ticket per connect, single-flight connect guard,
manual-close suppression, bounded backoff intervals.
[V] Real gaps: **D-G1** logout does not void outstanding unconsumed tickets
(≤30s window); **D-G2** established sockets survive logout/blacklist (no
connection-kill hook; pre-logout authority persists until disconnect);
**D-G3** client reconnect does not distinguish 4401 auth-close from network
close (could loop ticket requests; interplay with 401 handler could redirect
from background listener).
[O] Overturned: stale-ticket reuse on reconnect; ticket-in-URL; completer
leaks (broadcast design; the old completer-based WS service is dead code).
Fixing D properly = ticket-store invalidation API + logout hook + connection
registry kill + client close-code policy + tests on both sides: genuinely
cross-layer and security-relevant, but wider than one bounded change.

## Candidate E — Error envelope & state preservation

[V] Seven server body shapes exist (ApiResponse family incl. security JSON;
login raw map; register {status}/{error}; 429 login shape; legacy {error}
maps; framework problem bodies outside the chain; empty bodies). Client
fallback chain (base_api_client.dart:771-877, exception_mapper.dart) tolerates
all observed shapes; non-JSON/empty bodies preserve the HTTP status.
[V] E-G1: old-data preservation on refresh failure is per-controller folklore
(some clear-then-fetch, some preserve) — wide, shallow, client-only.
E-G3: envelope unification is already specified by the repo's own failing
regression test (error_responses_use_unified_api_response_format) — wide,
server-side. [O] Overturned: parser fragility.

## Baseline-blocking fact (affects any candidate's validation)

`mvn test` on untouched main fails 66F+10E of 87: LoginAttemptGuard counts
every login inspection against a 40/min-per-IP budget (inspectKey increments
before deciding, LoginAttemptGuard.java:110), recordSuccess clears only the
account key (:77), application-test.yml sets no app.security.login.*
overrides, and every test method re-logs-in from 127.0.0.1 → deterministic
lock cascade (429 observed in surefire reports). Pre-existing; not a Docker
or product-login defect. Consequence: suite-green is unreachable in EXP-005
scope; focused classes must be validated standalone (a single class stays
under the budget). Non-cascade pre-existing failures also exist (401-before-
404 for deprecated paths; envelope-unification assertions).

## Candidate scoring (0–5 per axis)

| Candidate | Real gap depth | Boundedness | Cross-layer contract | Testability now | Risk if changed | Verdict |
| --- | --- | --- | --- | --- | --- | --- |
| A session recovery | 4 (A-G1 app-wide session destruction) | 5 (one owner file + tests) | 4 (consumes Spring status contract; both sides testable) | 5 (http.Client seam; standalone Spring classes) | low | **SELECTED (narrow slice)** |
| B idempotency chain | 5 (live duplicate-record chain: fresh-key retries + 208→TypeError inviting resubmit) | 1 (honest repair spans multiple client submit sites + core parser semantics + backend 208-body/500/schema fixes) | 5 | 2 (208 contract fix forces caller-wide semantics decisions) | med | rejected FOR THIS ROUND: severity real, but no one-file honest slice exists — the 208 replay body itself lacks a business id, so a client-only fix cannot restore the contract |
| C authz projection | 3 (404/403 ordering leak + plate oracle + zero ownership tests) | 3 (server-side reorder is bounded but Flutter side has no product defect — thin dual-side value) | 2 | 3 | low | rejected: enforcement itself verified present; remaining fixes are server-only hardening + test debt, weak Flutter consumer leg |
| D ws lifecycle | 5 (D-G1/G2 real security holes) | 2 (needs registry kill + both sides) | 5 | 2 (WS harness cost high) | med-high | rejected FOR THIS ROUND: exceeds one bounded change; best Full-Loop-shaped future candidate |
| E envelope/state | 2 | 1 (wide-shallow both sides) | 3 | 3 | rejected slot | rejected: no bounded deep slice |

## Why A over B and D (the three real-gap leaders)

B and D both carry severe, verified gaps — B is a reachable duplicate-record
chain through normal user behavior, D is a session-revocation hole — but
neither can be honestly delivered as ONE bounded, independently-acceptable
change: B's repair requires a coordinated 208-body contract change (the
server's replay body carries no business id) plus key-lifecycle changes at
multiple client submit sites; D requires connection-kill semantics, multi-tab
policy, and dual-side close-code handling. A's gap is narrower but has an
app-wide user-visible blast radius today, a precise contract already emitted
by the server (401 terminal vs 429/5xx transient — verified), existing test
seams on both sides, and single-file product scope. B and D are recorded as
the strongest future Full-Loop-shaped candidates for this repository.

## Counterexample search results (Phase 8 §17)

1. Low-risk-looking but Full-Loop-worthy: **found** — E looks like "just a
   parser fix" but honest repair is wide on both sides (envelope unification
   + per-page state policy).
2. Cross-layer-looking but Lightweight-sufficient: **found** — A: auth-domain,
   cross-runtime contract in play, yet the defective code is one client file
   with direct tests. (C partially: server enforcement exists in code, but
   the deep pass showed its TEST claim was illusory — see reliability note.)
3. Hard trigger present but not worth implementing (this round): **found** —
   B and D: live, verified defect chains in hard-trigger domains
   (duplicate writes; WS security lifecycle) whose HONEST repair exceeds one
   bounded change — the correct disposition is recording them for
   Full-Loop-shaped future work, not cramming a partial fix into this round.
   NOTE the reversal risk this exposed: B initially read as "mitigated
   server-side" in a preliminary pass; only the deep pass (and Supervisor
   line-level verification) surfaced the live duplicate-record chain.
   Audit depth changes hard-trigger dispositions.
4. Artifact-budget misfit: **found** — experiment-mandated reporting (~13
   artifacts) exceeds the 4–7 Lightweight budget regardless of change size;
   see MODE-SELECTION.
5. Reviewer need MMGH never exercised: **partially** — MMGH never exercised
   Accessibility or a Flutter-platform reviewer; EXP-005 also finds no need
   for them (Operations/Accessibility stay off), but C-G2 exposes a
   *test-execution* review concern (Surefire include drift) that no MMGH
   reviewer axis names; recorded under Standards.
6. Load-profile shortfall to record but not fix: **found** — see RESULTS
   (H6): "pre-existing red baseline" guidance is absent from the frozen
   Lightweight profile (MMGH baselines were green).

## Unverified in this audit

Runtime behavior of WS under real logout (static analysis only), Flutter
mobile secure-storage behavior on devices, production gateway envelope
rewriting, PQC token paths (PqcTokenCrypto/TokenProviderMlDsa integration
tests not exercised standalone), and all excluded implementations.
