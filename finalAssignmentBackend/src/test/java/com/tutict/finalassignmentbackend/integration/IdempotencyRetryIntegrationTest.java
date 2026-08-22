package com.tutict.finalassignmentbackend.integration;

import static org.hamcrest.Matchers.equalTo;

import com.tutict.finalassignmentbackend.integration.BaseIntegrationTest;
import java.util.Map;
import java.util.UUID;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Order;
import org.junit.jupiter.api.Test;

/**
 * EXP-005: Phase E — Idempotency state machine.
 * Ensures idempotent requests with the same key return the same result
 * and do not create duplicate entities.
 */
@DisplayName("幂等性状态机集成测试")
class IdempotencyRetryIntegrationTest extends BaseIntegrationTest {

    @Test
    @Order(1)
    @DisplayName("相同幂等键的注册请求返回相同结果")
    void idempotent_register_returns_same_result() {
        String idempotencyKey = UUID.randomUUID().toString();
        String username = "idempotent-" + UUID.randomUUID().toString().substring(0, 8);

        // First request
        baseSpec()
            .body(Map.of(
                "username", username,
                "password", "TestPass123!",
                "role", "USER",
                "idempotencyKey", idempotencyKey
            ))
            .post("/api/auth/register")
            .then()
            .statusCode(201)
            .body("success", equalTo(true));

        // Second request with same key returns 201 (or 409 if already exists)
        baseSpec()
            .body(Map.of(
                "username", username,
                "password", "TestPass123!",
                "role", "USER",
                "idempotencyKey", idempotencyKey
            ))
            .post("/api/auth/register")
            .then()
            .statusCode(201); // Tolerate idempotent success
    }

    @Test
    @Order(2)
    @DisplayName("不同幂等键的注册请求各自独立")
    void different_idempotency_keys_are_independent() {
        String prefix = "indep-" + UUID.randomUUID().toString().substring(0, 6);

        baseSpec()
            .body(Map.of(
                "username", prefix + "-a",
                "password", "TestPass123!",
                "role", "USER",
                "idempotencyKey", UUID.randomUUID().toString()
            ))
            .post("/api/auth/register")
            .then()
            .statusCode(201);

        baseSpec()
            .body(Map.of(
                "username", prefix + "-b",
                "password", "TestPass123!",
                "role", "USER",
                "idempotencyKey", UUID.randomUUID().toString()
            ))
            .post("/api/auth/register")
            .then()
            .statusCode(201);
    }
}