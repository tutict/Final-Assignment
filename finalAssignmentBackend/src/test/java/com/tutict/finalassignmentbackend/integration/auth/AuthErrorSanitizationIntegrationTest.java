package com.tutict.finalassignmentbackend.integration.auth;

import static org.hamcrest.Matchers.equalTo;

import com.tutict.finalassignmentbackend.integration.BaseIntegrationTest;
import java.util.Map;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Order;
import org.junit.jupiter.api.Test;

/**
 * EXP-005: Phase I — Cloud auth consistency.
 * Login/register endpoints must return only generic error messages,
 * never ex.getMessage(), Feign exceptions, database errors, or internal URLs.
 */
@DisplayName("登录注册错误信息不泄露内部细节")
class AuthErrorSanitizationIntegrationTest extends BaseIntegrationTest {

    @Test
    @Order(1)
    @DisplayName("登录失败返回通用错误信息，不包含内部细节")
    void login_failure_returns_generic_message() {
        String body = baseSpec()
            .body(Map.of("username", "admin", "password", "WrongPassword"))
            .post("/api/auth/login")
            .then()
            .statusCode(401)
            .body("success", equalTo(false))
            .extract().asString();

        // Must never leak internal details
        org.assertj.core.api.Assertions.assertThat(body)
            .doesNotContain("FeignException")
            .doesNotContain("SQLException")
            .doesNotContain("DataIntegrityViolation")
            .doesNotContain("http://")
            .doesNotContain("localhost");
    }

    @Test
    @Order(2)
    @DisplayName("注册失败返回通用错误信息，不包含内部细节")
    void register_failure_returns_generic_message() {
        // Register with a duplicate username to trigger a conflict
        String body = baseSpec()
            .body(Map.of("username", "admin", "password", "ComplexPass123!", "role", "USER"))
            .post("/api/auth/register")
            .then()
            .statusCode(409)
            .extract().asString();

        // The response format is {"error": "Username already exists"} (not ApiResponse wrapper)
        // Verify no internal details are leaked
        org.assertj.core.api.Assertions.assertThat(body)
            .doesNotContain("FeignException")
            .doesNotContain("SQLException")
            .doesNotContain("DataIntegrityViolation")
            .doesNotContain("http://")
            .doesNotContain("localhost");
    }

    @Test
    @Order(3)
    @DisplayName("黑名单 token 被拒绝访问受保护端点")
    void blacklisted_token_is_rejected() {
        // loginAsAdmin() calls /api/auth/logout earlier in this class context — each
        // test class starts its own Spring context; within THIS class there is a
        // shared account budget. Reuse a fresh login and logout to blacklist.
        // Because the same approach also trips the per-IP budget, keep this test
        // independent: login once, logout to blacklist, then verify rejection.
        String token = baseSpec()
            .body(Map.of("username", "admin", "password", "Admin@123456"))
            .post("/api/auth/login")
            .then()
            .statusCode(200)
            .extract().path("accessToken");

        org.assertj.core.api.Assertions.assertThat(token).isNotNull();

        // Logout to blacklist the token
        baseSpec()
            .header("Authorization", "Bearer " + token)
            .post("/api/auth/logout")
            .then()
            .statusCode(200);

        // Token must now be rejected by a filter-gated endpoint
        baseSpec()
            .header("Authorization", "Bearer " + token)
            .body(Map.of("query", "test"))
            .post("/api/rag/query")
            .then()
            .statusCode(401);
    }
}