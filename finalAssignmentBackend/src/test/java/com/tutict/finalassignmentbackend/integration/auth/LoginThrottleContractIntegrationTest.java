package com.tutict.finalassignmentbackend.integration.auth;

import static org.hamcrest.Matchers.equalTo;
import static org.hamcrest.Matchers.greaterThanOrEqualTo;
import static org.hamcrest.Matchers.matchesPattern;

import com.tutict.finalassignmentbackend.integration.BaseIntegrationTest;
import java.util.Map;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Order;
import org.junit.jupiter.api.Test;
import org.springframework.test.context.TestPropertySource;

/**
 * EXP-005 characterization of the login-throttle contract shape consumed by
 * the Flutter client: a throttled login is 429 with a Retry-After header and
 * a {success:false, errorCode:LOGIN_RATE_LIMITED, retryAfterSeconds} body —
 * the transient-signal shape the client's session-recovery classification
 * (and, unimplemented today, its login UX) depends on.
 *
 * Runs in its own Spring context with a tiny per-account window so the trip
 * is deterministic and never pollutes the shared context's per-IP budget —
 * the same per-IP budget whose exhaustion by test-suite logins is the
 * recorded pre-existing cause of the baseline mvn-test cascade
 * (see docs/experiments/looppilot-phase8-exp005/BASELINE-OBSERVATIONS.md).
 */
@TestPropertySource(properties = {
    "app.security.login.max-account-attempts=2",
    "app.security.login.max-ip-attempts=100",
    "app.security.login.window=PT1M",
    "app.security.login.lock-duration=PT2M",
    "app.security.login.failure-penalty-after=50",
    "app.security.login.max-consecutive-failures=50",
    "app.security.login.failure-penalty-base=PT0.001S"
})
@DisplayName("登录限流契约：429 + Retry-After + LOGIN_RATE_LIMITED")
class LoginThrottleContractIntegrationTest extends BaseIntegrationTest {

    @Test
    @Order(1)
    @DisplayName("超过账号窗口配额 → 429 信封携带 Retry-After 与 retryAfterSeconds")
    void throttled_login_returns_429_with_retry_after_contract() {
        Map<String, String> probe =
            Map.of("username", "exp005-throttle-probe", "password", "WrongPassword1!");

        for (int attempt = 0; attempt < 2; attempt++) {
            baseSpec()
                .body(probe)
                .post("/api/auth/login")
                .then()
                .statusCode(401)
                .body("success", equalTo(false));
        }

        baseSpec()
            .body(probe)
            .post("/api/auth/login")
            .then()
            .statusCode(429)
            .header("Retry-After", matchesPattern("\\d+"))
            .body("success", equalTo(false))
            .body("errorCode", equalTo("LOGIN_RATE_LIMITED"))
            .body("retryAfterSeconds", greaterThanOrEqualTo(1));
    }

    @Test
    @Order(2)
    @DisplayName("成功登录清空账号窗口计数：连续成功登录不会被账号配额锁定")
    void successful_logins_do_not_trip_the_account_budget() {
        for (int attempt = 0; attempt < 3; attempt++) {
            baseSpec()
                .body(Map.of("username", "admin", "password", "Admin@123456"))
                .post("/api/auth/login")
                .then()
                .statusCode(200);
        }
    }
}
