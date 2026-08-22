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
 * EXP-005: Phase G — Login rate limit proxy IP trust.
 * Ensures the login throttle keys on the client IP derived from trusted proxy
 * headers, not unvalidated X-Forwarded-For values.
 */
@TestPropertySource(properties = {
    "app.security.login.max-account-attempts=2",
    "app.security.login.max-ip-attempts=100",
    "app.security.login.window=PT1M",
    "app.security.login.failure-penalty-after=50",
    "app.security.login.max-consecutive-failures=50",
    "app.security.login.failure-penalty-base=PT0.001S"
})
@DisplayName("登录限流代理 IP 信任集成测试")
class RateLimitProxyHeaderIntegrationTest extends BaseIntegrationTest {

    @Test
    @Order(1)
    @DisplayName("构造的 X-Forwarded-For 头不触发 IP 级限流绕过")
    void forged_x_forwarded_for_does_not_bypass_rate_limit() {
        Map<String, String> probe =
            Map.of("username", "exp005-proxy-probe", "password", "WrongPassword1!");

        // With maxAccountAttempts=2, the first 2 attempts should be 401 (allowed but wrong password)
        for (int attempt = 0; attempt < 2; attempt++) {
            baseSpec()
                .header("X-Forwarded-For", "1.2.3." + attempt)
                .body(probe)
                .post("/api/auth/login")
                .then()
                .statusCode(401)
                .body("success", equalTo(false));
        }

        // The 3rd attempt with the same account, even with a different X-Forwarded-For,
        // should be 429 (account budget exhausted) because the untrusted proxy header
        // is ignored and the real remoteAddr (127.0.0.1) is used for the account key.
        baseSpec()
            .header("X-Forwarded-For", "1.2.3.9")
            .body(probe)
            .post("/api/auth/login")
            .then()
            .statusCode(429)
            .header("Retry-After", matchesPattern("\\d+"))
            .body("success", equalTo(false))
            .body("errorCode", equalTo("LOGIN_RATE_LIMITED"))
            .body("retryAfterSeconds", greaterThanOrEqualTo(1));
    }
}