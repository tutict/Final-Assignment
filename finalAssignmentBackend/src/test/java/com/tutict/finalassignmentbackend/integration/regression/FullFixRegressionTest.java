package com.tutict.finalassignmentbackend.integration.regression;

import static org.hamcrest.Matchers.equalTo;
import static org.hamcrest.Matchers.notNullValue;

import com.tutict.finalassignmentbackend.integration.BaseIntegrationTest;
import java.util.Map;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Order;
import org.junit.jupiter.api.Test;

/**
 * EXP-005 comprehensive regression test covering all fix phases.
 * Runs the core business flows that all phases must not break.
 */
@DisplayName("Full-Fix 回归测试")
class FullFixRegressionTest extends BaseIntegrationTest {

    @Test
    @Order(1)
    @DisplayName("登录 → 访问受保护端点 → 登出 → 黑名单拒绝")
    void login_access_logout_blacklist() {
        String token = loginAsAdmin();

        authSpec(token).get("/api/auth/me")
            .then().statusCode(200).body("success", equalTo(true));

        authSpec(token).post("/api/auth/logout").then().statusCode(200);

        authSpec(token).get("/api/auth/me")
            .then().statusCode(401).body("success", equalTo(false));
    }

    @Test
    @Order(2)
    @DisplayName("登录成功返回 token 且不泄露密码")
    void login_does_not_leak_password() {
        String body = baseSpec()
            .body(Map.of("username", "testuser", "password", "User@123456"))
            .post("/api/auth/login")
            .then().statusCode(200)
            .extract().asString();

        org.assertj.core.api.Assertions.assertThat(body)
            .doesNotContain("\"password\"")
            .doesNotContain("\"salt\"")
            .doesNotContain("\"passwordHash\"");
    }

    @Test
    @Order(3)
    @DisplayName("注册新用户后可用新用户登录")
    void register_and_login_works() {
        String username = "regtest-" + System.currentTimeMillis();

        baseSpec()
            .body(Map.of("username", username, "password", "NewPass123!", "role", "USER"))
            .post("/api/auth/register")
            .then().statusCode(201);

        baseSpec()
            .body(Map.of("username", username, "password", "NewPass123!"))
            .post("/api/auth/login")
            .then().statusCode(200)
            .body("accessToken", notNullValue());
    }
}