# EXP-005 Baseline Observations

Date: 2026-07-20. All items below are `observed` unless labeled otherwise.

## Stage 0 — Git reality check

| Item | Value |
| --- | --- |
| Repo toplevel | C:/Users/tutic/IdeaProjects/Final-Assignment |
| Remote | origin = https://github.com/tutict/Final-Assignment.git (fetch/push) |
| Initial branch | main |
| Initial HEAD | ba3b49d83e1f73aeab8392fd5a5292d6961b058e ("Harden auth boundaries and token handling") — matches the known baseline |
| origin/main after fetch | ba3b49d83e1f73aeab8392fd5a5292d6961b058e; main...origin/main = 0/0 |
| Working tree | one pre-existing uncommitted modification: `.gitignore` (adds .gradle/, .claude/, .codex/, .agents/, *.pid/*.seed/*.trace/*.dump ignore rules; removes a self-ignoring `.gitignore` line) |
| Pre-existing work disposition | preserved untouched; excluded from experiment commits (explicit-path staging); recorded as pre-existing excluded work |
| Other worktrees | codex/go-update and codex/spring-cloud-update are checked out in separate worktrees (Final-Assignment-go, Final-Assignment-spring-cloud); untouched |
| Experiment branch | experiment/looppilot-final-assignment-exp-005 created from main @ ba3b49d8; no prior branch of that name existed |
| LoopPilot frozen HEAD | 298205fb87ca937e0765ef41024085538344d6e7, working tree clean, read-only throughout |

LoopPilot files actually loaded (read-only): SKILL.md, AGENTS.md,
docs/mode-selection-and-escalation.md, docs/protocol-load-profiles.md,
docs/evaluation-synthesis-and-protocol-calibration.md,
docs/mmgh-behavioral-evidence.md, .looppilot/ templates
(PROJECT-TEMPLATE.md, STATE.md, CHECKLIST.md, HANDOFF.md).

## Tool versions (observed)

| Tool | Version |
| --- | --- |
| Java | 25 LTS, Oracle GraalVM 25+37.1 |
| Maven | 3.9.12 (no repo wrapper — `mvnw` absent; system mvn used) |
| Flutter | 3.44.4 stable (framework ad70ec4617) |
| Dart | 3.12.2 stable |
| Git | 2.51.0.windows.1 |
| Docker | client 28.4.0; daemon initially DOWN (named pipe missing) → Execution Infrastructure Incident EII-1; recovered by starting Docker Desktop; server 28.4.0 afterwards |

## Spring Boot baseline (finalAssignmentBackend @ ba3b49d8)

- `mvn -DskipTests compile`: BUILD SUCCESS, 2:48 min.
- `mvn -DskipTests package`: run started at baseline (result recorded in RESULTS).
- `mvn test`: **BUILD FAILURE — Tests run: 87, Failures: 66, Errors: 10, Skipped: 0.**

### Surefire actual scope (observed)

`pom.xml` Surefire `<includes>` runs ONLY `**/*IntegrationTest.java` and
`**/*RegressionTest.java`. The ~34 plain `*Test.java` unit-test classes in
src/test are **not executed** by `mvn test`. A green `mvn test` therefore never
meant "all tests pass"; new tests must match the include pattern to run.

### Root cause of the 76 baseline failures (observed, pre-existing on main)

- `BaseIntegrationTest.USE_TESTCONTAINERS` defaults to **false**; the test
  profile targets local services (MySQL localhost:3306 `traffic_test`,
  Redis localhost:6379; Kafka listeners auto-startup=false). The Spring context
  started and endpoints answered — local services were reachable, so this is
  NOT a Docker/Testcontainers failure.
- Dominant cascade: `BaseIntegrationTest.loginAs:71` fails in `setUp` with
  observed statuses **429** (and consequent 401/NullPointer downstream).
  Verified chain: `LoginAttemptGuard` counts every inspected attempt per IP
  (`inspectKey` increments `windowAttempts` before deciding, line 110) with
  `max-ip-attempts` default 40/min; `recordSuccess` invalidates only the
  account key (line 77), so **successful logins still consume the IP budget**;
  `application-test.yml` sets **no** `app.security.login.*` overrides; each of
  the ~87 test methods logs in at least once from 127.0.0.1 → IP budget
  exhausts → 2-minute lock → cascading 429/401 setup failures.
- Independent non-cascade failures also observed (pre-existing):
  `deprecated_paths_return_404_or_410` — `/api/roles/name/ADMIN` returns 401,
  expected 404/410; `error_responses_use_unified_api_response_format` failed;
  `refresh_token_rotation_invalidates_old_token` NullPointer (line 109) —
  consistent with the cascade exhausting login before the refresh chain.
- Classification: pre-existing baseline failure on untouched main. The
  rate-limiter/test-suite interplay is a repository test-design vs product
  configuration mismatch — not an Execution Infrastructure Incident (services
  and tools operated normally) and not proof of a product login defect.

Duration: `mvn test` ≈ 6.5 min wall clock. No skipped tests. No dependency
download failures. Environment variables: none required beyond defaults
(TEST_DB_* fall back to root/root localhost).

## Flutter baseline (final_assignment_front @ ba3b49d8)

- `flutter pub get`: success ("Got dependencies"); 37 packages have newer
  incompatible versions (not upgraded — dependency freeze respected).
- `dart format --output=none --set-exit-if-changed lib test`: **4 files would
  be reformatted** (pre-existing, main): core/network/field_validation_error.dart,
  features/api/user_management_controller_api.dart,
  features/dashboard/controllers/user_dashboard_screen_controller.dart,
  features/dashboard/views/shared/components/profile_tile.dart.
  (Earlier interim log line "format exit: 0" was a shell-pipeline artifact —
  the exit code observed belonged to `tail`; the authoritative observation is
  the tool's own "4 changed" output. Corrected here.)
- `flutter analyze`: 1 pre-existing warning — unused_local_variable
  `newDecodedToken` at features/dashboard/views/manager/pages/main_process/vehicle_list.dart:107.
- `flutter test`: **10 tests, all passed** — 3 files only:
  features/ai/sse_streaming_parser_test.dart (4),
  security/token_security_regression_test.dart (6, includes secure-storage,
  no-token-in-URL, no-token-in-log regressions), widget_test.dart (1 construct).
- `flutter build web --release`: run started at baseline (result in RESULTS).

## Boundary file hashes at baseline (git hash-object)

| File | SHA-1 |
| --- | --- |
| finalAssignmentBackend/pom.xml | 3268d2e9d43f21364d03138ac731ecb7c7ddac5c |
| final_assignment_front/pubspec.yaml | e18e56a23444a591e422b7bb0230d80711c357a6 |
| final_assignment_front/pubspec.lock | 570c2bb551b0a0b9c563845cc2f6d58737eed922 |

No dependency upgrades are planned or performed in EXP-005.

## Execution Infrastructure Incidents (running log)

- **EII-1** — Docker daemon unavailable at session start (Docker Desktop
  Linux-engine named pipe missing). Recovery: started Docker Desktop;
  daemon 28.4.0 confirmed up. Impact: none on final evidence (integration
  tests turned out not to use Testcontainers by default), recorded for H5.

## Excluded implementations (evidence of exclusion)

finalAssignmentCloud, final_assignment_backend_go,
final_assignment_backend_quarkus, final_assignment_front_react were not
read for implementation, not built, not tested, and receive no diffs in this
experiment (verified again at final `git diff --stat main...HEAD`).
