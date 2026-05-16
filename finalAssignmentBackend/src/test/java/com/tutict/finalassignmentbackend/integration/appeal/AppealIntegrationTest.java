package com.tutict.finalassignmentbackend.integration.appeal;

import static org.assertj.core.api.Assertions.assertThat;
import static org.awaitility.Awaitility.await;
import static org.hamcrest.Matchers.anyOf;
import static org.hamcrest.Matchers.empty;
import static org.hamcrest.Matchers.equalTo;
import static org.hamcrest.Matchers.is;
import static org.hamcrest.Matchers.not;
import static org.hamcrest.Matchers.notNullValue;

import com.tutict.finalassignmentbackend.integration.BaseIntegrationTest;
import com.tutict.finalassignmentbackend.integration.TestDataFactory;
import java.time.Duration;
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

@DisplayName("申诉业务流集成测试")
@TestMethodOrder(MethodOrderer.OrderAnnotation.class)
class AppealIntegrationTest extends BaseIntegrationTest {

    private String adminToken;
    private String userToken;
    private Long offenseId;

    @BeforeEach
    void setUp() {
        adminToken = loginAsAdmin();
        userToken = loginAsUser();
        offenseId = createPrerequisiteOffense();
    }

    @Test
    @Order(1)
    @DisplayName("用户提交申诉：必填字段完整时返回 201")
    void user_submits_appeal_with_all_required_fields() {
        authSpec(userToken)
            .header("Idempotency-Key", newIdempotencyKey())
            .body(TestDataFactory.validAppeal(offenseId))
            .post("/api/appeals")
            .then()
            .statusCode(anyOf(is(200), is(201)))
            .body("success", equalTo(true))
            .body("data.appealId", notNullValue())
            .body("data.processStatus", anyOf(equalTo("Pending"), equalTo("Unprocessed")));
    }

    @Test
    @Order(2)
    @DisplayName("申诉缺少必填字段：idCard/contact/reason 返回 400 + 字段级错误")
    void appeal_missing_required_fields_returns_field_level_errors() {
        authSpec(userToken)
            .header("Idempotency-Key", newIdempotencyKey())
            .body(Map.of(
                "offenseId", offenseId,
                "appellantName", "张测试"
            ))
            .post("/api/appeals")
            .then()
            .statusCode(400)
            .body("success", equalTo(false))
            .body("errorCode", equalTo("VALIDATION_ERROR"))
            .body("data", not(empty()))
            .body("data.find { it.field == 'idCard' }", notNullValue());
    }

    @Test
    @Order(3)
    @DisplayName("重复申诉：相同 Idempotency-Key 返回 208")
    void duplicate_appeal_submission_returns_208() {
        String key = newIdempotencyKey();
        Map<String, Object> body = TestDataFactory.validAppeal(offenseId);

        authSpec(userToken).header("Idempotency-Key", key)
            .body(body).post("/api/appeals")
            .then().statusCode(anyOf(is(200), is(201)));

        authSpec(userToken).header("Idempotency-Key", key)
            .body(body).post("/api/appeals")
            .then()
            .statusCode(208)
            .body("success", equalTo(true));
    }

    @Test
    @Order(4)
    @DisplayName("管理员审批：必须先 START_REVIEW 再 APPROVE，直接 APPROVE 返回 409")
    void approve_without_start_review_returns_409() {
        Long appealId = createTestAppeal(offenseId);

        authSpec(adminToken)
            .post("/api/workflow/appeals/{id}/events/{event}", appealId, "APPROVE")
            .then()
            .statusCode(409)
            .body("errorCode", anyOf(equalTo("WORKFLOW_CONFLICT"), equalTo("CONFLICT")));
    }

    @Test
    @Order(5)
    @DisplayName("完整审批流程：START_REVIEW → APPROVE → 状态变为 Approved")
    void full_appeal_approval_workflow_succeeds() {
        Long appealId = createTestAppeal(offenseId);

        authSpec(adminToken)
            .post("/api/workflow/appeals/{id}/events/{event}", appealId, "START_REVIEW")
            .then()
            .statusCode(anyOf(is(200), is(201)));

        authSpec(adminToken)
            .get("/api/appeals/{id}", appealId)
            .then()
            .body("data.processStatus", anyOf(equalTo("Under_Review"), equalTo("UnderReview")));

        authSpec(adminToken)
            .post("/api/workflow/appeals/{id}/events/{event}", appealId, "APPROVE")
            .then()
            .statusCode(anyOf(is(200), is(201)));

        authSpec(adminToken)
            .get("/api/appeals/{id}", appealId)
            .then()
            .statusCode(200)
            .body("data.processStatus", equalTo("Approved"));
    }

    @Test
    @Order(6)
    @DisplayName("完整拒绝流程：START_REVIEW → REJECT → 状态变为 Rejected")
    void full_appeal_rejection_workflow_succeeds() {
        Long appealId = createTestAppeal(offenseId);

        authSpec(adminToken)
            .post("/api/workflow/appeals/{id}/events/{event}", appealId, "START_REVIEW")
            .then().statusCode(anyOf(is(200), is(201)));

        authSpec(adminToken)
            .post("/api/workflow/appeals/{id}/events/{event}", appealId, "REJECT")
            .then().statusCode(anyOf(is(200), is(201)));

        authSpec(adminToken)
            .get("/api/appeals/{id}", appealId)
            .then()
            .body("data.processStatus", equalTo("Rejected"));
    }

    @Test
    @Order(7)
    @DisplayName("并发审批：两个管理员同时审批同一申诉，只有一个成功")
    void concurrent_appeal_approval_only_one_succeeds() throws Exception {
        Long appealId = createTestAppeal(offenseId);

        ExecutorService executor = Executors.newFixedThreadPool(2);
        List<Future<Integer>> startReviewFutures = List.of(
            executor.submit(() -> authSpec(adminToken)
                .post("/api/workflow/appeals/{id}/events/{event}", appealId, "START_REVIEW").statusCode()),
            executor.submit(() -> authSpec(adminToken)
                .post("/api/workflow/appeals/{id}/events/{event}", appealId, "START_REVIEW").statusCode())
        );
        executor.shutdown();
        executor.awaitTermination(5, TimeUnit.SECONDS);

        List<Integer> codes = startReviewFutures.stream()
            .map(f -> {
                try {
                    return f.get();
                } catch (Exception e) {
                    return -1;
                }
            })
            .collect(Collectors.toList());

        assertThat(codes).anyMatch(c -> c == 200 || c == 201);
        long successCount = codes.stream().filter(c -> c == 200 || c == 201).count();
        assertThat(successCount).isLessThanOrEqualTo(1);
    }

    @Test
    @Order(8)
    @DisplayName("申诉审批后：Kafka Consumer 处理完成，数据库状态一致")
    void appeal_approval_kafka_consumer_updates_db() {
        Long appealId = createTestAppeal(offenseId);

        authSpec(adminToken)
            .post("/api/workflow/appeals/{id}/events/{event}", appealId, "START_REVIEW")
            .then().statusCode(anyOf(is(200), is(201)));

        authSpec(adminToken)
            .post("/api/workflow/appeals/{id}/events/{event}", appealId, "APPROVE")
            .then().statusCode(anyOf(is(200), is(201)));

        await().atMost(Duration.ofSeconds(5))
            .pollInterval(Duration.ofMillis(500))
            .untilAsserted(() ->
                authSpec(adminToken)
                    .get("/api/appeals/{id}", appealId)
                    .then()
                    .body("data.processStatus", equalTo("Approved"))
            );
    }

    private Long createTestAppeal(Long offenseId) {
        return authSpec(userToken)
            .header("Idempotency-Key", newIdempotencyKey())
            .body(TestDataFactory.validAppeal(offenseId))
            .post("/api/appeals")
            .then().extract().path("data.appealId");
    }

    private Long createPrerequisiteOffense() {
        String adminTok = loginAsAdmin();
        Long driverId = authSpec(adminTok)
            .header("Idempotency-Key", newIdempotencyKey())
            .body(TestDataFactory.validDriver())
            .post("/api/drivers")
            .then().extract().path("data.driverId");

        Long vehicleId = authSpec(adminTok)
            .header("Idempotency-Key", newIdempotencyKey())
            .body(TestDataFactory.validVehicle(driverId))
            .post("/api/vehicles")
            .then().extract().path("data.vehicleId");

        return authSpec(adminTok)
            .header("Idempotency-Key", newIdempotencyKey())
            .body(TestDataFactory.validOffense(driverId, vehicleId))
            .post("/api/offenses")
            .then().extract().path("data.offenseId");
    }
}
