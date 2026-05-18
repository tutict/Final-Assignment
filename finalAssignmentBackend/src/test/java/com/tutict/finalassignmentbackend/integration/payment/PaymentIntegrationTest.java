package com.tutict.finalassignmentbackend.integration.payment;

import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.anyOf;
import static org.hamcrest.Matchers.equalTo;
import static org.hamcrest.Matchers.is;
import static org.hamcrest.Matchers.notNullValue;
import static org.hamcrest.Matchers.nullValue;

import com.tutict.finalassignmentbackend.integration.BaseIntegrationTest;
import com.tutict.finalassignmentbackend.integration.TestDataFactory;
import java.util.ArrayList;
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

@DisplayName("支付业务流集成测试")
@TestMethodOrder(MethodOrderer.OrderAnnotation.class)
class PaymentIntegrationTest extends BaseIntegrationTest {

    private String adminToken;
    private Long fineId;
    private Long offenseId;

    @BeforeEach
    void setUp() {
        adminToken = loginAsAdmin();
        offenseId = createPrerequisiteOffense();
        fineId = createPrerequisiteFine(offenseId);
    }

    @Test
    @Order(1)
    @DisplayName("创建支付记录：必填字段完整返回 201")
    void create_payment_record_with_required_fields() {
        authSpec(adminToken)
            .header("Idempotency-Key", newIdempotencyKey())
            .body(TestDataFactory.validPayment(fineId))
            .post("/api/payments")
            .then()
            .statusCode(anyOf(is(200), is(201)))
            .body("success", equalTo(true))
            .body("data.paymentId", notNullValue())
            .body("data.idempotencyKey", nullValue());
    }

    @Test
    @Order(2)
    @DisplayName("创建支付缺少 fineId：返回 400 VALIDATION_ERROR")
    void create_payment_missing_fine_id_returns_400() {
        authSpec(adminToken)
            .header("Idempotency-Key", newIdempotencyKey())
            .body(Map.of(
                "paymentAmount", 200.0,
                "paymentMethod", "微信支付",
                "payerName", "张测试"
            ))
            .post("/api/payments")
            .then()
            .statusCode(400)
            .body("errorCode", equalTo("VALIDATION_ERROR"));
    }

    @Test
    @Order(3)
    @DisplayName("更新支付状态：携带幂等键 + 大写枚举值 → 成功")
    void update_payment_status_with_idempotency_key_and_uppercase_enum() {
        Long paymentId = createTestPayment(fineId);

        authSpec(adminToken)
            .header("Idempotency-Key", newIdempotencyKey())
            .put("/api/payments/{id}/status/{state}", paymentId, "PAID")
            .then()
            .statusCode(anyOf(is(200), is(204)))
            .body("success", equalTo(true));

        authSpec(adminToken)
            .get("/api/payments/{id}", paymentId)
            .then()
            .body("data.paymentStatus", anyOf(equalTo("PAID"), equalTo("Paid")));
    }

    @Test
    @Order(4)
    @DisplayName("更新支付状态：不携带幂等键返回 400（必填 header）")
    void update_payment_status_without_idempotency_key_returns_400() {
        Long paymentId = createTestPayment(fineId);

        authSpec(adminToken)
            .put("/api/payments/{id}/status/{state}", paymentId, "PAID")
            .then()
            .statusCode(400);
    }

    @Test
    @Order(5)
    @DisplayName("更新支付状态：小写枚举值 paid 返回 400（后端要求 PAID）")
    void update_payment_status_lowercase_enum_returns_400() {
        Long paymentId = createTestPayment(fineId);

        authSpec(adminToken)
            .header("Idempotency-Key", newIdempotencyKey())
            .put("/api/payments/{id}/status/{state}", paymentId, "paid")
            .then()
            .statusCode(400);
    }

    @Test
    @Order(6)
    @DisplayName("支付状态幂等：相同 Idempotency-Key 重复提交返回 208")
    void payment_status_update_idempotent_returns_208() {
        Long paymentId = createTestPayment(fineId);
        String key = newIdempotencyKey();

        authSpec(adminToken)
            .header("Idempotency-Key", key)
            .put("/api/payments/{id}/status/{state}", paymentId, "PAID")
            .then().statusCode(anyOf(is(200), is(204)));

        authSpec(adminToken)
            .header("Idempotency-Key", key)
            .put("/api/payments/{id}/status/{state}", paymentId, "PAID")
            .then()
            .statusCode(208)
            .body("success", equalTo(true));
    }

    @Test
    @Order(7)
    @DisplayName("乐观锁保护：并发更新同一支付记录，只有一个成功")
    void concurrent_payment_update_optimistic_lock_prevents_lost_update() throws Exception {
        Long paymentId = createTestPayment(fineId);

        ExecutorService executor = Executors.newFixedThreadPool(3);
        List<Future<Integer>> futures = new ArrayList<>();

        for (int i = 0; i < 3; i++) {
            futures.add(executor.submit(() ->
                authSpec(adminToken)
                    .header("Idempotency-Key", newIdempotencyKey())
                    .put("/api/payments/{id}/status/{state}", paymentId, "PAID")
                    .statusCode()));
        }
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

        long successCount = codes.stream().filter(c -> c == 200 || c == 204).count();
        assertThat(successCount).isLessThanOrEqualTo(1);
        assertThat(codes).anyMatch(c -> c == 409 || c == 208);
    }

    @Test
    @Order(8)
    @DisplayName("支付 Workflow 事件触发：返回合法状态")
    void payment_workflow_event_triggers_with_correct_enum() {
        Long paymentId = createTestPayment(fineId);

        authSpec(adminToken)
            .post("/api/workflow/payments/{id}/events/{event}", paymentId, "COMPLETE_PAYMENT")
            .then()
            .statusCode(anyOf(is(200), is(201), is(409)));
    }

    @Test
    @Order(9)
    @DisplayName("支付记录列表：返回 ApiResponse 包装，不是裸 List")
    void payment_list_returns_api_response_wrapped() {
        authSpec(adminToken)
            .queryParam("page", 0)
            .queryParam("size", 10)
            .get("/api/payments")
            .then()
            .statusCode(200)
            .body("success", equalTo(true))
            .body("data", notNullValue());
    }

    private Long createTestPayment(Long fineId) {
        return authSpec(adminToken)
            .header("Idempotency-Key", newIdempotencyKey())
            .body(TestDataFactory.validPayment(fineId))
            .post("/api/payments")
            .then().extract().path("data.paymentId");
    }

    private Long createPrerequisiteOffense() {
        Long driverId = authSpec(adminToken)
            .header("Idempotency-Key", newIdempotencyKey())
            .body(TestDataFactory.validDriver())
            .post("/api/drivers")
            .then().extract().path("data.driverId");
        Long vehicleId = authSpec(adminToken)
            .header("Idempotency-Key", newIdempotencyKey())
            .body(TestDataFactory.validVehicle(driverId))
            .post("/api/vehicles")
            .then().extract().path("data.vehicleId");
        return authSpec(adminToken)
            .header("Idempotency-Key", newIdempotencyKey())
            .body(TestDataFactory.validOffense(driverId, vehicleId))
            .post("/api/offenses")
            .then().extract().path("data.offenseId");
    }

    private Long createPrerequisiteFine(Long offenseId) {
        return authSpec(adminToken)
            .header("Idempotency-Key", newIdempotencyKey())
            .body(TestDataFactory.validFine(offenseId))
            .post("/api/fines")
            .then().extract().path("data.fineId");
    }
}
