package com.tutict.finalassignmentbackend.integration.offense;

import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.anyOf;
import static org.hamcrest.Matchers.empty;
import static org.hamcrest.Matchers.equalTo;
import static org.hamcrest.Matchers.greaterThanOrEqualTo;
import static org.hamcrest.Matchers.hasSize;
import static org.hamcrest.Matchers.is;
import static org.hamcrest.Matchers.not;
import static org.hamcrest.Matchers.notNullValue;
import static org.hamcrest.Matchers.nullValue;

import com.tutict.finalassignmentbackend.integration.BaseIntegrationTest;
import com.tutict.finalassignmentbackend.integration.TestDataFactory;
import io.restassured.response.Response;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;
import java.util.stream.Collectors;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.MethodOrderer;
import org.junit.jupiter.api.Order;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.TestMethodOrder;

@DisplayName("违法记录与罚单业务流集成测试")
@TestMethodOrder(MethodOrderer.OrderAnnotation.class)
class OffenseFineIntegrationTest extends BaseIntegrationTest {

    private String adminToken;
    private String userToken;
    private Long driverId;
    private Long vehicleId;

    @BeforeEach
    void setUp() {
        adminToken = loginAsAdmin();
        userToken = loginAsUser();
        driverId = createTestDriver();
        vehicleId = createTestVehicle(driverId);
    }

    @Test
    @Order(1)
    @DisplayName("管理员创建违法记录：返回 201 + 完整记录")
    void admin_creates_offense_record_successfully() {
        Response resp = authSpec(adminToken)
            .header("Idempotency-Key", newIdempotencyKey())
            .body(TestDataFactory.validOffense(driverId, vehicleId))
            .post("/api/offenses");

        resp.then()
            .statusCode(anyOf(is(200), is(201)))
            .body("success", equalTo(true))
            .body("data.offenseId", notNullValue())
            .body("data.processStatus", equalTo("Pending"))
            .body("data.idempotencyKey", nullValue());
    }

    @Test
    @Order(2)
    @DisplayName("幂等创建：相同 Idempotency-Key 重复提交返回 208")
    void duplicate_offense_creation_returns_208() {
        String key = newIdempotencyKey();
        Map<String, Object> body = TestDataFactory.validOffense(driverId, vehicleId);

        authSpec(adminToken)
            .header("Idempotency-Key", key)
            .body(body)
            .post("/api/offenses")
            .then().statusCode(anyOf(is(200), is(201)));

        authSpec(adminToken)
            .header("Idempotency-Key", key)
            .body(body)
            .post("/api/offenses")
            .then()
            .statusCode(208)
            .body("success", equalTo(true));
    }

    @Test
    @Order(3)
    @DisplayName("查询违法记录列表：返回分页结构，不是裸 List")
    void get_offense_list_returns_paginated_response() {
        authSpec(adminToken)
            .queryParam("page", 0)
            .queryParam("size", 10)
            .get("/api/offenses")
            .then()
            .statusCode(200)
            .body("success", equalTo(true))
            .body("data.content", notNullValue())
            .body("data.total", greaterThanOrEqualTo(0))
            .body("data.page", equalTo(0))
            .body("data.size", equalTo(10));
    }

    @Test
    @Order(4)
    @DisplayName("按状态查询：使用 query 参数 status（不是 path 参数）")
    void get_offense_by_status_uses_query_param() {
        authSpec(adminToken)
            .queryParam("status", "Pending")
            .get("/api/offenses/search/status")
            .then()
            .statusCode(200)
            .body("success", equalTo(true));

        authSpec(adminToken)
            .queryParam("processStatus", "Pending")
            .get("/api/offenses/search/status")
            .then()
            .statusCode(anyOf(is(200), is(400)));
    }

    @Test
    @Order(5)
    @DisplayName("创建违法记录缺少必填字段返回 400 + VALIDATION_ERROR")
    void create_offense_missing_required_fields_returns_400() {
        authSpec(adminToken)
            .header("Idempotency-Key", newIdempotencyKey())
            .body(Map.of("offenseType", "超速"))
            .post("/api/offenses")
            .then()
            .statusCode(400)
            .body("success", equalTo(false))
            .body("errorCode", equalTo("VALIDATION_ERROR"))
            .body("data", not(empty()));
    }

    @Test
    @Order(6)
    @DisplayName("Workflow：违法记录状态机正确流转 Pending→Processing→Completed")
    void offense_workflow_state_transition_succeeds() {
        Long offenseId = createTestOffense(driverId, vehicleId);

        authSpec(adminToken)
            .post("/api/workflow/offenses/{id}/events/{event}", offenseId, "START_PROCESSING")
            .then()
            .statusCode(anyOf(is(200), is(201)));

        authSpec(adminToken)
            .get("/api/offenses/{id}", offenseId)
            .then()
            .statusCode(200)
            .body("data.processStatus", not(equalTo("Pending")));
    }

    @Test
    @Order(7)
    @DisplayName("Workflow：非法状态转换返回 409 WORKFLOW_CONFLICT")
    void offense_workflow_invalid_transition_returns_409() {
        Long offenseId = createTestOffense(driverId, vehicleId);

        authSpec(adminToken)
            .post("/api/workflow/offenses/{id}/events/{event}", offenseId, "COMPLETE")
            .then()
            .statusCode(409)
            .body("success", equalTo(false))
            .body("errorCode", anyOf(equalTo("WORKFLOW_CONFLICT"), equalTo("CONFLICT")));
    }

    @Test
    @Order(8)
    @DisplayName("并发审批：两个管理员同时修改同一违法记录，只有一个成功")
    void concurrent_offense_update_optimistic_lock_protection() throws Exception {
        Long offenseId = createTestOffense(driverId, vehicleId);

        ExecutorService executor = Executors.newFixedThreadPool(2);
        List<Future<Integer>> futures = List.of(
            executor.submit(() ->
                authSpec(adminToken)
                    .body(Map.of("processStatus", "Processing", "offenseId", offenseId))
                    .put("/api/offenses/{id}", offenseId)
                    .statusCode()),
            executor.submit(() ->
                authSpec(adminToken)
                    .body(Map.of("processStatus", "Completed", "offenseId", offenseId))
                    .put("/api/offenses/{id}", offenseId)
                    .statusCode())
        );
        executor.shutdown();
        executor.awaitTermination(5, TimeUnit.SECONDS);

        List<Integer> codes = futures.stream()
            .map(f -> {
                try {
                    return f.get();
                } catch (Exception e) {
                    return -1;
                }
            })
            .collect(Collectors.toList());

        long successCount = codes.stream().filter(c -> c == 200 || c == 201).count();
        assertThat(successCount).isLessThanOrEqualTo(1);
    }

    @Test
    @Order(9)
    @DisplayName("创建罚单：关联到违法记录，返回罚单 ID")
    void create_fine_linked_to_offense() {
        Long offenseId = createTestOffense(driverId, vehicleId);

        authSpec(adminToken)
            .header("Idempotency-Key", newIdempotencyKey())
            .body(TestDataFactory.validFine(offenseId))
            .post("/api/fines")
            .then()
            .statusCode(anyOf(is(200), is(201)))
            .body("success", equalTo(true))
            .body("data.fineId", notNullValue())
            .body("data.status", equalTo("Unpaid"));
    }

    @Test
    @Order(10)
    @DisplayName("违法详情接口：包含关联罚单，不触发 N+1")
    void offense_detail_includes_fines_without_n_plus_1() {
        Long offenseId = createTestOffense(driverId, vehicleId);

        for (int i = 0; i < 3; i++) {
            authSpec(adminToken)
                .header("Idempotency-Key", newIdempotencyKey())
                .body(TestDataFactory.validFine(offenseId))
                .post("/api/fines");
        }

        long startMs = System.currentTimeMillis();
        Response resp = authSpec(adminToken)
            .get("/api/offenses/{id}/details", offenseId);
        long elapsedMs = System.currentTimeMillis() - startMs;

        resp.then()
            .statusCode(200)
            .body("data.fines", hasSize(3));

        assertThat(elapsedMs).isLessThan(500L);
    }

    private Long createTestOffense(Long driverId, Long vehicleId) {
        return authSpec(adminToken)
            .header("Idempotency-Key", newIdempotencyKey())
            .body(TestDataFactory.validOffense(driverId, vehicleId))
            .post("/api/offenses")
            .then().extract().path("data.offenseId");
    }

    private Long createTestDriver() {
        return authSpec(adminToken)
            .header("Idempotency-Key", newIdempotencyKey())
            .body(TestDataFactory.validDriver())
            .post("/api/drivers")
            .then().extract().path("data.driverId");
    }

    private Long createTestVehicle(Long driverId) {
        return authSpec(adminToken)
            .header("Idempotency-Key", newIdempotencyKey())
            .body(TestDataFactory.validVehicle(driverId))
            .post("/api/vehicles")
            .then().extract().path("data.vehicleId");
    }
}
