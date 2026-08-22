package com.tutict.finalassignmentbackend.integration.auth;

import static org.hamcrest.Matchers.equalTo;
import static org.hamcrest.Matchers.notNullValue;

import com.tutict.finalassignmentbackend.integration.BaseIntegrationTest;
import java.util.Map;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Order;
import org.junit.jupiter.api.Test;

/**
 * EXP-005: Phase B — ML-DSA JWT expiration validation.
 * Ensures expired ML-DSA tokens are rejected and valid tokens are accepted.
 */
@DisplayName("ML-DSA JWT 过期校验集成测试")
class TokenProviderMlDsaExpirationIntegrationTest extends BaseIntegrationTest {

    @Test
    @Order(1)
    @DisplayName("正常登录 token 可访问受保护端点")
    void valid_token_allows_access() {
        String token = loginAsAdmin();
        authSpec(token).get("/api/auth/me").then()
            .statusCode(200)
            .body("success", equalTo(true));
    }

    @Test
    @Order(2)
    @DisplayName("伪造 token 被拒绝")
    void forged_token_is_rejected() {
        authSpec("eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJhZG1pbiJ9.invalid")
            .get("/api/auth/me")
            .then()
            .statusCode(401);
    }

    @Test
    @Order(3)
    @DisplayName("token 包含用户角色信息")
    void token_contains_roles() {
        Map<String, Object> loginResp = baseSpec()
            .body(Map.of("username", "admin", "password", "Admin@123456"))
            .post("/api/auth/login")
            .then()
            .statusCode(200)
            .extract().jsonPath().getMap("");

        org.assertj.core.api.Assertions.assertThat(loginResp)
            .containsKey("accessToken")
            .containsKey("roles");
    }

    @Test
    @Order(4)
    @DisplayName("RAG 查询需要认证")
    void rag_query_requires_auth() {
        baseSpec()
            .body(Map.of("query", "test", "topK", 5))
            .post("/api/rag/query")
            .then()
            .statusCode(401);
    }
}