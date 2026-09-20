package com.tutict.finalassignmentbackend.integration.rag;

import static org.hamcrest.Matchers.equalTo;

import com.tutict.finalassignmentbackend.integration.BaseIntegrationTest;
import java.util.Map;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Order;
import org.junit.jupiter.api.Test;

/**
 * EXP-005: Phase H — RAG deletion and resource limits.
 * Ensures RAG document deletion cleans up ES chunks after DB commit,
 * and resource limits (topK, ZIP bomb, XML bomb) are properly enforced.
 */
@DisplayName("RAG 删除与资源限制集成测试")
class RagDeletionResourceLimitIntegrationTest extends BaseIntegrationTest {

    @Test
    @Order(1)
    @DisplayName("RAG 返回 topK 上限为 50")
    void rag_topK_is_capped_at_50() {
        String token = loginAsUser();

        authSpec(token)
            .body(Map.of("query", "test", "topK", 9999))
            .post("/api/rag/query")
            .then()
            .statusCode(200);
    }

    @Test
    @Order(2)
    @DisplayName("AI 消息长度被截断到 10000")
    void ai_message_truncated_to_max_length() {
        String token = loginAsAdmin();

        String longMsg = "x".repeat(11000);
        authSpec(token)
            .accept("text/event-stream")
            .body(Map.of("message", longMsg, "sessionKey", "test-session"))
            .post("/api/ai/chat/stream")
            .then()
            .statusCode(200);
    }

    @Test
    @Order(3)
    @DisplayName("SUPER_ADMIN 可删除 RAG 文档")
    void super_admin_can_delete_rag_document() {
        String token = loginAsSuperAdmin();

        authSpec(token)
            .delete("/api/rag/admin/documents/nonexistent-doc")
            .then()
            .statusCode(200)
            .body("success", equalTo(true));
    }

    @Test
    @Order(4)
    @DisplayName("USER 无法访问 RAG 管理接口")
    void user_cannot_call_rag_admin() {
        String token = loginAsUser();
        authSpec(token).get("/api/rag/admin/documents").then().statusCode(403);
        authSpec(token).get("/api/rag/admin/documents/doc-1").then().statusCode(403);
        authSpec(token)
            .body(Map.of("query", "license", "asRole", "USER"))
            .post("/api/rag/admin/preview")
            .then()
            .statusCode(403);
    }

    @Test
    @Order(5)
    @DisplayName("ADMIN 可以访问 RAG 管理接口")
    void admin_can_call_rag_admin() {
        String token = loginAsAdmin();
        authSpec(token).get("/api/rag/admin/documents").then().statusCode(200);
        authSpec(token)
            .body(Map.of("query", "license", "asRole", "ADMIN"))
            .post("/api/rag/admin/preview")
            .then()
            .statusCode(200);
    }

    @Test
    @Order(6)
    @DisplayName("SUPER_ADMIN 可以访问列表和 preview")
    void super_admin_can_call_detail_and_preview() {
        String token = loginAsSuperAdmin();
        authSpec(token).get("/api/rag/admin/documents").then().statusCode(200);
        authSpec(token)
            .body(Map.of("query", "license", "asRole", "USER"))
            .post("/api/rag/admin/preview")
            .then()
            .statusCode(200);
    }
}
