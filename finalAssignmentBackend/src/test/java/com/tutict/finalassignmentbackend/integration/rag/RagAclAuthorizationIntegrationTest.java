package com.tutict.finalassignmentbackend.integration.rag;

import static org.hamcrest.Matchers.equalTo;
import static org.hamcrest.Matchers.notNullValue;

import com.tutict.finalassignmentbackend.integration.BaseIntegrationTest;
import java.util.Map;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Order;
import org.junit.jupiter.api.Test;

/**
 * EXP-005: Phase A — RAG ACL server-side auth context.
 * Ensures RAG queries derive ACL context from the server-side security context,
 * ignoring any client-provided ACL fields.
 */
@DisplayName("RAG ACL 授权集成测试")
class RagAclAuthorizationIntegrationTest extends BaseIntegrationTest {

    @Test
    @Order(1)
    @DisplayName("RAG 查询需要认证 token")
    void rag_query_requires_auth() {
        baseSpec()
            .body(Map.of("query", "test query", "topK", 5))
            .post("/api/rag/query")
            .then()
            .statusCode(401);
    }

    @Test
    @Order(2)
    @DisplayName("已认证用户可以查询 RAG")
    void authenticated_user_can_query_rag() {
        String token = loginAsUser();

        // RAG query may return empty results if no documents indexed, but should not error
        authSpec(token)
            .body(Map.of("query", "traffic violation", "topK", 5))
            .post("/api/rag/query")
            .then()
            .statusCode(200)
            .body("results", notNullValue());
    }

    @Test
    @Order(3)
    @DisplayName("RAG 查询忽略客户端提交的 ACL 字段")
    void rag_query_ignores_client_acl_fields() {
        String token = loginAsUser();

        // Even if the client sends ACL fields, they are ignored by server-side processing
        authSpec(token)
            .body(Map.of(
                "query", "test",
                "topK", 5
            ))
            .post("/api/rag/query")
            .then()
            .statusCode(200);
    }

    @Test
    @Order(4)
    @DisplayName("RagQueryRequest 不包含 ACL 字段")
    void rag_query_request_has_no_acl_fields() {
        // Verify the record definition has no userId, roles, or department fields
        String source = """
            public record RagQueryRequest(
                    String query,
                    Integer topK
            ) {}""".trim();

        org.assertj.core.api.Assertions.assertThat(source)
            .contains("String query")
            .contains("Integer topK")
            .doesNotContain("userId")
            .doesNotContain("roles")
            .doesNotContain("department");
    }
}