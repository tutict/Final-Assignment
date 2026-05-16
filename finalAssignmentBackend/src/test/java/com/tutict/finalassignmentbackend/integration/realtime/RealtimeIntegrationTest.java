package com.tutict.finalassignmentbackend.integration.realtime;

import static io.restassured.RestAssured.given;
import static org.assertj.core.api.Assertions.assertThat;
import static org.junit.jupiter.api.Assertions.fail;
import static org.junit.jupiter.api.Assumptions.assumeTrue;
import static org.hamcrest.Matchers.anyOf;
import static org.hamcrest.Matchers.containsString;
import static org.hamcrest.Matchers.equalTo;
import static org.hamcrest.Matchers.is;
import static org.hamcrest.Matchers.notNullValue;

import com.tutict.finalassignmentbackend.config.websocket.WsActionRegistry;
import com.tutict.finalassignmentbackend.integration.BaseIntegrationTest;
import io.restassured.http.ContentType;
import io.restassured.response.Response;
import java.util.Map;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.MethodOrderer;
import org.junit.jupiter.api.Order;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.TestMethodOrder;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.core.env.Environment;
import org.springframework.test.util.ReflectionTestUtils;

@DisplayName("实时通信业务流集成测试")
@TestMethodOrder(MethodOrderer.OrderAnnotation.class)
class RealtimeIntegrationTest extends BaseIntegrationTest {

    private String adminToken;

    @Autowired
    private WsActionRegistry wsActionRegistry;

    @Autowired
    private Environment environment;

    @BeforeEach
    void setUp() {
        adminToken = loginAsAdmin();
    }

    @Test
    @Order(1)
    @DisplayName("WsActionRegistry：启动后注册表不为空")
    void ws_action_registry_is_not_empty_after_startup() {
        Map<String, ?> registry = registry();
        assertThat(registry)
            .withFailMessage(
                "WsActionRegistry 为空！检查 BASE_PACKAGE 配置。当前注册数量: " + registry.size())
            .isNotEmpty();
    }

    @Test
    @Order(2)
    @DisplayName("WsActionRegistry：AuthWsService 的 login action 已注册")
    void auth_ws_service_login_action_is_registered() {
        Map<String, ?> registry = registry();
        boolean hasAuthLogin = registry.keySet().stream()
            .anyMatch(k -> k.contains("AuthWsService") && k.contains("login"));

        assertThat(hasAuthLogin)
            .withFailMessage("AuthWsService#login 未注册，WebSocket 登录功能不可用")
            .isTrue();
    }

    @Test
    @Order(3)
    @DisplayName("SSE：POST /api/ai/chat/stream 返回 text/event-stream")
    void ai_chat_stream_returns_sse_content_type() {
        Response response = given()
            .baseUri("http://localhost").port(port)
            .header("Authorization", "Bearer " + adminToken)
            .contentType(ContentType.JSON)
            .body(Map.of(
                "message", "你好，请简单介绍一下自己",
                "sessionKey", UUID.randomUUID().toString()
            ))
            .when()
            .post("/api/ai/chat/stream");

        response.then().statusCode(anyOf(is(200), is(503)));
        if (response.statusCode() == 200) {
            response.then().header("Content-Type", containsString("text/event-stream"));
        } else {
            response.then()
                .contentType(containsString("application/json"))
                .body("success", equalTo(false));
        }
    }

    @Test
    @Order(4)
    @DisplayName("SSE：streaming 禁用时返回 503 ApiResponse 格式（不是空 body）")
    void ai_chat_stream_disabled_returns_503_with_api_response() {
        assumeTrue(isStreamingDisabled(), "跳过：当前 streaming 已启用，此测试仅在禁用时有效");

        given()
            .baseUri("http://localhost").port(port)
            .header("Authorization", "Bearer " + adminToken)
            .contentType(ContentType.JSON)
            .body(Map.of("message", "test"))
            .when()
            .post("/api/ai/chat/stream")
            .then()
            .statusCode(503)
            .contentType(containsString("application/json"))
            .body("success", equalTo(false))
            .body("errorCode", equalTo("SERVICE_UNAVAILABLE"))
            .body("message", notNullValue());
    }

    @Test
    @Order(5)
    @DisplayName("SSE：未认证请求返回 401（不是白名单）")
    void ai_chat_stream_requires_authentication() {
        given()
            .baseUri("http://localhost").port(port)
            .contentType(ContentType.JSON)
            .body(Map.of("message", "test"))
            .when()
            .post("/api/ai/chat/stream")
            .then()
            .statusCode(401)
            .body("success", equalTo(false));
    }

    @Test
    @Order(6)
    @DisplayName("SSE：旧 GET /api/ai/chat 返回 410 Gone")
    void legacy_get_ai_chat_returns_410() {
        given()
            .baseUri("http://localhost").port(port)
            .header("Authorization", "Bearer " + adminToken)
            .when()
            .get("/api/ai/chat")
            .then()
            .statusCode(410)
            .body("errorCode", equalTo("GONE"));
    }

    @Test
    @Order(7)
    @DisplayName("进度查询：使用 query 参数 status（不是 path 参数）")
    void progress_status_query_uses_query_param_not_path_param() {
        authSpec(adminToken)
            .queryParam("status", "Pending")
            .get("/api/progress/status")
            .then()
            .statusCode(anyOf(is(200), is(400)));

        authSpec(adminToken)
            .get("/api/progress/status/Pending")
            .then()
            .statusCode(404);
    }

    @Test
    @Order(8)
    @DisplayName("进度时间范围接口：应存在（或返回明确的 404/410）")
    void progress_time_range_endpoint_exists_or_returns_meaningful_error() {
        Response resp = authSpec(adminToken)
            .queryParam("startTime", "2024-01-01T00:00:00")
            .queryParam("endTime", "2024-12-31T23:59:59")
            .get("/api/progress/timeRange");

        int status = resp.statusCode();
        if (status == 404) {
            fail("进度时间范围接口不存在 (404)，需要后端补充实现。参考修复 harness Step 3 的 ProgressItemController 新增接口。");
        }
        assertThat(status).isIn(200, 400);
    }

    @SuppressWarnings("unchecked")
    private Map<String, ?> registry() {
        Object value = ReflectionTestUtils.getField(wsActionRegistry, "registry");
        assertThat(value).isInstanceOf(Map.class);
        return (Map<String, ?>) value;
    }

    private boolean isStreamingDisabled() {
        return !environment.getProperty("ai.chat.streaming.enabled", Boolean.class, true);
    }
}
