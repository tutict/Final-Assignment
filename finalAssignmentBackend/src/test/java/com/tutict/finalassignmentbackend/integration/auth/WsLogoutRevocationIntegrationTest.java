package com.tutict.finalassignmentbackend.integration.auth;

import static org.hamcrest.Matchers.equalTo;
import static org.hamcrest.Matchers.notNullValue;
import static org.hamcrest.Matchers.nullValue;

import com.tutict.finalassignmentbackend.integration.BaseIntegrationTest;
import java.util.Map;
import java.util.UUID;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Order;
import org.junit.jupiter.api.Test;

/**
 * EXP-005: Phase F — WebSocket logout lifecycle.
 * Ensures logout invalidates WebSocket tickets and responses do not leak
 * sensitive user fields.
 */
@DisplayName("WebSocket 登出生命周期集成测试")
class WsLogoutRevocationIntegrationTest extends BaseIntegrationTest {

    @Test
    @Order(1)
    @DisplayName("用户列表接口不泄露敏感字段")
    void user_list_does_not_leak_sensitive_fields() {
        String token = loginAsAdmin();

        String body = authSpec(token)
            .get("/api/auth/users")
            .then()
            .statusCode(200)
            .extract().asString();

        org.assertj.core.api.Assertions.assertThat(body)
            .doesNotContain("idCardNumber")
            .doesNotContain("contactNumber")
            .doesNotContain("passwordHash")
            .doesNotContain("loginFailures");
    }

    @Test
    @Order(2)
    @DisplayName("登出后访问受保护端点返回 401")
    void logout_revokes_access() {
        String token = loginAsAdmin();

        authSpec(token).post("/api/auth/logout").then().statusCode(200);

        authSpec(token).get("/api/auth/me").then()
            .statusCode(401)
            .body("success", equalTo(false));
    }

    @Test
    @Order(3)
    @DisplayName("登出后 ws-ticket 签发失败")
    void logout_revokes_ws_ticket_generation() {
        String token = loginAsAdmin();

        // Before logout a ticket can be issued
        authSpec(token).post("/api/ws-ticket").then()
            .statusCode(200);

        authSpec(token).post("/api/auth/logout").then().statusCode(200);

        // After logout the ticket issuance should fail
        authSpec(token).post("/api/ws-ticket").then()
            .statusCode(401);
    }
}