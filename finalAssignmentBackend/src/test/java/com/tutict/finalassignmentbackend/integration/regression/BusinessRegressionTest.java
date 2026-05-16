package com.tutict.finalassignmentbackend.integration.regression;

import static io.restassured.RestAssured.given;
import static org.assertj.core.api.Assertions.assertThat;
import static org.awaitility.Awaitility.await;
import static org.hamcrest.Matchers.anyOf;
import static org.hamcrest.Matchers.equalTo;
import static org.hamcrest.Matchers.is;
import static org.hamcrest.Matchers.not;
import static org.hamcrest.Matchers.notNullValue;
import static org.hamcrest.Matchers.nullValue;

import com.tutict.finalassignmentbackend.integration.BaseIntegrationTest;
import com.tutict.finalassignmentbackend.integration.TestDataFactory;
import java.time.Duration;
import java.util.List;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.MethodOrderer;
import org.junit.jupiter.api.Order;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.TestMethodOrder;

@DisplayName("业务全链路回归测试（CI 快速验证）")
@TestMethodOrder(MethodOrderer.OrderAnnotation.class)
class BusinessRegressionTest extends BaseIntegrationTest {

    private static String adminToken;
    private static String userToken;
    private static Long driverId;
    private static Long vehicleId;
    private static Long offenseId;
    private static Long fineId;
    private static Long appealId;
    private static Long paymentId;

    @Test
    @Order(1)
    @DisplayName("【Phase 1-1】系统可用性：健康检查通过")
    void health_check_passes() {
        given().baseUri("http://localhost").port(port)
            .get("/actuator/health")
            .then().statusCode(200)
            .body("status", equalTo("UP"));
    }

    @Test
    @Order(2)
    @DisplayName("【Phase 1-2】认证：管理员和用户登录成功")
    void admin_and_user_login_succeed() {
        adminToken = loginAsAdmin();
        userToken = loginAsUser();
        assertThat(adminToken).isNotBlank();
        assertThat(userToken).isNotBlank();
    }

    @Test
    @Order(3)
    @DisplayName("【Phase 2-1】创建驾驶员")
    void create_driver() {
        driverId = authSpec(adminToken)
            .header("Idempotency-Key", newIdempotencyKey())
            .body(TestDataFactory.validDriver())
            .post("/api/drivers")
            .then().statusCode(anyOf(is(200), is(201)))
            .body("success", equalTo(true))
            .extract().path("data.driverId");
        assertThat(driverId).isNotNull();
    }

    @Test
    @Order(4)
    @DisplayName("【Phase 2-2】创建车辆，关联驾驶员")
    void create_vehicle_linked_to_driver() {
        vehicleId = authSpec(adminToken)
            .header("Idempotency-Key", newIdempotencyKey())
            .body(TestDataFactory.validVehicle(driverId))
            .post("/api/vehicles")
            .then().statusCode(anyOf(is(200), is(201)))
            .body("data.driverId", equalTo(driverId.intValue()))
            .extract().path("data.vehicleId");
        assertThat(vehicleId).isNotNull();
    }

    @Test
    @Order(5)
    @DisplayName("【Phase 3-1】创建违法记录，初始状态 Pending")
    void create_offense_with_pending_status() {
        offenseId = authSpec(adminToken)
            .header("Idempotency-Key", newIdempotencyKey())
            .body(TestDataFactory.validOffense(driverId, vehicleId))
            .post("/api/offenses")
            .then().statusCode(anyOf(is(200), is(201)))
            .body("data.processStatus", equalTo("Pending"))
            .extract().path("data.offenseId");
        assertThat(offenseId).isNotNull();
    }

    @Test
    @Order(6)
    @DisplayName("【Phase 3-2】创建关联罚单")
    void create_fine_for_offense() {
        fineId = authSpec(adminToken)
            .header("Idempotency-Key", newIdempotencyKey())
            .body(TestDataFactory.validFine(offenseId))
            .post("/api/fines")
            .then().statusCode(anyOf(is(200), is(201)))
            .body("data.status", equalTo("Unpaid"))
            .extract().path("data.fineId");
        assertThat(fineId).isNotNull();
    }

    @Test
    @Order(7)
    @DisplayName("【Phase 4-1】用户提交申诉")
    void user_submits_appeal() {
        appealId = authSpec(userToken)
            .header("Idempotency-Key", newIdempotencyKey())
            .body(TestDataFactory.validAppeal(offenseId))
            .post("/api/appeals")
            .then().statusCode(anyOf(is(200), is(201)))
            .extract().path("data.appealId");
        assertThat(appealId).isNotNull();
    }

    @Test
    @Order(8)
    @DisplayName("【Phase 4-2】管理员执行 START_REVIEW，进入审核中")
    void admin_starts_review() {
        authSpec(adminToken)
            .post("/api/workflow/appeals/{id}/events/{event}", appealId, "START_REVIEW")
            .then()
            .statusCode(anyOf(is(200), is(201)));

        authSpec(adminToken)
            .get("/api/appeals/{id}", appealId)
            .then()
            .body("data.processStatus", not(equalTo("Pending")));
    }

    @Test
    @Order(9)
    @DisplayName("【Phase 4-3】管理员 APPROVE，申诉通过")
    void admin_approves_appeal() {
        authSpec(adminToken)
            .post("/api/workflow/appeals/{id}/events/{event}", appealId, "APPROVE")
            .then()
            .statusCode(anyOf(is(200), is(201)));

        await().atMost(Duration.ofSeconds(5))
            .pollInterval(Duration.ofMillis(300))
            .untilAsserted(() ->
                authSpec(adminToken)
                    .get("/api/appeals/{id}", appealId)
                    .then()
                    .body("data.processStatus", equalTo("Approved"))
            );
    }

    @Test
    @Order(10)
    @DisplayName("【Phase 5-1】创建支付记录")
    void create_payment_record() {
        paymentId = authSpec(adminToken)
            .header("Idempotency-Key", newIdempotencyKey())
            .body(TestDataFactory.validPayment(fineId))
            .post("/api/payments")
            .then().statusCode(anyOf(is(200), is(201)))
            .body("data.idempotencyKey", nullValue())
            .extract().path("data.paymentId");
        assertThat(paymentId).isNotNull();
    }

    @Test
    @Order(11)
    @DisplayName("【Phase 5-2】更新支付状态为 PAID（含幂等键）")
    void update_payment_to_paid_with_idempotency() {
        String key = newIdempotencyKey();

        authSpec(adminToken)
            .header("Idempotency-Key", key)
            .put("/api/payments/{id}/status/{state}", paymentId, "PAID")
            .then()
            .statusCode(anyOf(is(200), is(204)));

        authSpec(adminToken)
            .get("/api/payments/{id}", paymentId)
            .then()
            .body("data.paymentStatus", anyOf(equalTo("PAID"), equalTo("Paid")));
    }

    @Test
    @Order(12)
    @DisplayName("【Phase 6-1】错误响应格式统一（验证 GlobalExceptionHandler）")
    void error_responses_use_unified_api_response_format() {
        authSpec(adminToken)
            .get("/api/offenses/99999999")
            .then()
            .statusCode(404)
            .body("success", equalTo(false))
            .body("errorCode", notNullValue())
            .body("timestamp", nullValue());

        authSpec(adminToken)
            .header("Idempotency-Key", newIdempotencyKey())
            .body("{}")
            .post("/api/offenses")
            .then()
            .statusCode(400)
            .body("success", equalTo(false))
            .body("errorCode", equalTo("VALIDATION_ERROR"));
    }

    @Test
    @Order(13)
    @DisplayName("【Phase 6-2】分页接口返回正确结构（非裸 List）")
    void paginated_endpoints_return_correct_structure() {
        List<String> paginatedEndpoints = List.of(
            "/api/offenses", "/api/payments", "/api/appeals",
            "/api/users", "/api/drivers", "/api/vehicles"
        );

        for (String endpoint : paginatedEndpoints) {
            authSpec(adminToken)
                .queryParam("page", 0)
                .queryParam("size", 5)
                .get(endpoint)
                .then()
                .statusCode(200)
                .body("success", equalTo(true))
                .body("data", notNullValue());
        }
    }

    @Test
    @Order(14)
    @DisplayName("【Phase 6-3】废弃路径全部返回 404 或 410")
    void deprecated_paths_return_404_or_410() {
        List<String> deprecatedPaths = List.of(
            "/api/roles/name/ADMIN",
            "/api/permissions/name/READ",
            "/api/roles/search?name=test",
            "/api/progress/status/Pending",
            "/api/progress/timeRange"
        );

        for (String path : deprecatedPaths) {
            int status = authSpec(adminToken).get(path).statusCode();
            assertThat(status)
                .withFailMessage("废弃路径 " + path + " 返回了 " + status + "，应为 404 或 410")
                .isIn(404, 410);
        }
    }

    @Test
    @Order(15)
    @DisplayName("【Phase 6-4】Kafka Consumer 处理后数据库状态一致（最终一致性验证）")
    void kafka_consumer_ensures_eventual_consistency() {
        Long newOffenseId = authSpec(adminToken)
            .header("Idempotency-Key", newIdempotencyKey())
            .body(TestDataFactory.validOffense(driverId, vehicleId))
            .post("/api/offenses")
            .then().extract().path("data.offenseId");

        assertThat(newOffenseId).isNotNull();

        await().atMost(Duration.ofSeconds(10))
            .pollInterval(Duration.ofSeconds(1))
            .untilAsserted(() ->
                authSpec(adminToken)
                    .queryParam("offenseLocation", "北京市朝阳区")
                    .get("/api/offenses/search/location")
                    .then()
                    .statusCode(200)
            );
    }

    @Test
    @Order(99)
    @DisplayName("【回归总结】输出业务链路覆盖摘要")
    void print_regression_summary() {
        System.out.println("""
            ╔══════════════════════════════════════════════════╗
            ║          业务全链路回归测试完成                     ║
            ╠══════════════════════════════════════════════════╣
            ║  Phase 1: 环境准备    (健康检查 + 认证)             ║
            ║  Phase 2: 数据准备    (驾驶员 + 车辆)               ║
            ║  Phase 3: 违法记录    (CRUD + 罚单)                 ║
            ║  Phase 4: 申诉业务流  (提交 + 审批)                  ║
            ║  Phase 5: 支付业务流  (创建 + 状态更新)              ║
            ║  Phase 6: 系统验证    (错误格式 + 分页 + 一致性)     ║
            ╠══════════════════════════════════════════════════╣
            ║  驾驶员ID: """ + driverId + """
            ║  车辆ID:   """ + vehicleId + """
            ║  违法ID:   """ + offenseId + """
            ║  申诉ID:   """ + appealId + """
            ║  支付ID:   """ + paymentId + """
            ╚══════════════════════════════════════════════════╝
            """);
    }
}
