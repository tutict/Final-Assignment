package com.tutict.finalassignmentbackend.integration.auth;

import static org.hamcrest.Matchers.equalTo;
import static org.hamcrest.Matchers.notNullValue;

import com.tutict.finalassignmentbackend.integration.BaseIntegrationTest;
import java.util.Map;
import java.util.UUID;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Order;
import org.junit.jupiter.api.Test;

/**
 * EXP-005: Phase D — Refresh token O(N) lookup fix.
 * Ensures refresh tokens are found by digest (O(1)) and rotation works correctly.
 */
@DisplayName("Refresh Token 查询集成测试")
class RefreshTokenLookupIntegrationTest extends BaseIntegrationTest {

    @Test
    @Order(1)
    @DisplayName("登录返回 refreshToken")
    void login_returns_refresh_token() {
        Map<String, Object> resp = baseSpec()
            .body(Map.of("username", "testuser", "password", "User@123456"))
            .post("/api/auth/login")
            .then()
            .statusCode(200)
            .extract().jsonPath().getMap("");

        org.assertj.core.api.Assertions.assertThat(resp)
            .containsKey("refreshToken");
        org.assertj.core.api.Assertions.assertThat(resp.get("refreshToken"))
            .isNotNull();
    }

    @Test
    @Order(2)
    @DisplayName("refreshToken 可换取新 token")
    void refresh_token_rotation_works() {
        String refreshToken = baseSpec()
            .body(Map.of("username", "testuser", "password", "User@123456"))
            .post("/api/auth/login")
            .then().extract().path("refreshToken");

        org.assertj.core.api.Assertions.assertThat(refreshToken).isNotNull();

        baseSpec()
            .body(Map.of("refreshToken", refreshToken))
            .post("/api/auth/refresh")
            .then()
            .statusCode(200)
            .body("success", equalTo(true))
            .body("data.accessToken", notNullValue())
            .body("data.refreshToken", notNullValue());
    }

    @Test
    @Order(3)
    @DisplayName("refreshToken 不可重复使用（rotation 安全）")
    void refresh_token_cannot_be_reused() {
        String refreshToken = baseSpec()
            .body(Map.of("username", "testuser", "password", "User@123456"))
            .post("/api/auth/login")
            .then().extract().path("refreshToken");

        // First rotation succeeds
        baseSpec()
            .body(Map.of("refreshToken", refreshToken))
            .post("/api/auth/refresh")
            .then().statusCode(200);

        // Second rotation with same token fails
        baseSpec()
            .body(Map.of("refreshToken", refreshToken))
            .post("/api/auth/refresh")
            .then()
            .statusCode(401)
            .body("success", equalTo(false));
    }
}