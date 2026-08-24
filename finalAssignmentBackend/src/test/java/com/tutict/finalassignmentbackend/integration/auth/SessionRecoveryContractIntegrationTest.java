package com.tutict.finalassignmentbackend.integration.auth;

import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.anyOf;
import static org.hamcrest.Matchers.equalTo;
import static org.hamcrest.Matchers.is;
import static org.hamcrest.Matchers.notNullValue;

import com.tutict.finalassignmentbackend.integration.BaseIntegrationTest;
import io.restassured.response.Response;
import java.util.Map;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Order;
import org.junit.jupiter.api.Test;

/**
 * EXP-005 characterization of the session-recovery contract consumed by the
 * Flutter client (final_assignment_front AuthService).
 *
 * The client classifies refresh outcomes as terminal (400/401/403 — destroy
 * the local session) versus transient (408/429/5xx/network — preserve stored
 * tokens and retry later). These tests pin the server side of that contract:
 * an explicit rejection is always a 4xx ApiResponse envelope, never a 5xx,
 * and the refresh endpoint is not subject to the login rate limiter.
 */
@DisplayName("会话恢复契约：refresh 终局拒绝与成功轮换")
class SessionRecoveryContractIntegrationTest extends BaseIntegrationTest {

    @Test
    @Order(1)
    @DisplayName("垃圾 refreshToken → 401 终局拒绝，ApiResponse 信封")
    void refresh_with_unknown_token_is_rejected_with_401_envelope() {
        baseSpec()
            .body(Map.of("refreshToken", "exp005-not-a-real-refresh-token"))
            .post("/api/auth/refresh")
            .then()
            .statusCode(401)
            .body("success", equalTo(false))
            .body("errorCode", notNullValue());
    }

    @Test
    @Order(2)
    @DisplayName("空 refreshToken → 400/401 终局类，绝不是 5xx")
    void refresh_with_blank_token_is_rejected_as_terminal() {
        baseSpec()
            .body(Map.of("refreshToken", ""))
            .post("/api/auth/refresh")
            .then()
            .statusCode(anyOf(is(400), is(401)))
            .body("success", equalTo(false));
    }

    @Test
    @Order(3)
    @DisplayName("有效 refresh → 200 信封携带轮换后的新 token 对")
    void refresh_rotation_returns_envelope_with_new_token_pair() {
        Response login = baseSpec()
            .body(Map.of("username", "admin", "password", "Admin@123456"))
            .post("/api/auth/login");
        login.then().statusCode(200);
        String oldRefreshToken = login.then().extract().path("refreshToken");
        assertThat(oldRefreshToken).isNotBlank();

        Response refresh = baseSpec()
            .body(Map.of("refreshToken", oldRefreshToken))
            .post("/api/auth/refresh");

        refresh.then()
            .statusCode(200)
            .body("success", equalTo(true))
            .body("data.accessToken", notNullValue())
            .body("data.refreshToken", notNullValue());
        String rotated = refresh.then().extract().path("data.refreshToken");
        assertThat(rotated)
            .as("rotation must issue a new refresh token")
            .isNotEqualTo(oldRefreshToken);
    }

    @Test
    @Order(4)
    @DisplayName("refresh 不受登录限流：重复失败仍是 401，从不 429")
    void refresh_endpoint_is_not_login_throttled() {
        for (int attempt = 0; attempt < 10; attempt++) {
            int status = baseSpec()
                .body(Map.of("refreshToken", "exp005-invalid-" + attempt))
                .post("/api/auth/refresh")
                .statusCode();
            assertThat(status)
                .as("attempt %d must stay a terminal 401, never 429", attempt)
                .isEqualTo(401);
        }
    }
}
