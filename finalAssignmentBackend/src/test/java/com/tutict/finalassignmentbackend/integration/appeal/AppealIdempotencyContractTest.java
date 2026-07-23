package com.tutict.finalassignmentbackend.integration.appeal;

import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.equalTo;
import static org.hamcrest.Matchers.nullValue;

import com.tutict.finalassignmentbackend.integration.BaseIntegrationTest;
import com.tutict.finalassignmentbackend.integration.TestDataFactory;
import io.restassured.response.Response;
import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;

@DisplayName("Authenticated appeal create idempotency contract")
class AppealIdempotencyContractTest extends BaseIntegrationTest {

    private static final String CROSS_LAYER_FIXTURE_KEY = "EXP006-CROSS-LAYER-KEY-0001";

    @Autowired
    private JdbcTemplate jdbcTemplate;

    private String userToken;
    private Long userDriverId;
    private Long offenseId;

    @BeforeEach
    void setUp() {
        userToken = loginAsUser();
        userDriverId = extractLong(authSpec(userToken).get("/api/auth/me"), "data.driverId");
        offenseId = createPrerequisiteOffense();
    }

    @Test
    void sequentialRetryReturns208AndLeavesOneTraceableAppeal() {
        jdbcTemplate.update("DELETE FROM sys_request_history WHERE idempotency_key = ?", CROSS_LAYER_FIXTURE_KEY);
        String key = CROSS_LAYER_FIXTURE_KEY;
        Map<String, Object> body = appealBody();
        body.put("driverId", -1L);

        Response created = postAppeal(key, body);
        Long appealId = extractLong(created, "data.appealId");
        created.then().statusCode(201).body("success", equalTo(true));
        assertAuthenticatedIdentity(appealId);

        postAppeal(key, body).then()
                .statusCode(208)
                .body("success", equalTo(true))
                .body("data", nullValue());

        assertTrace(key, appealId, 1);

        String secondKey = newIdempotencyKey();
        Response secondCreated = postAppeal(secondKey, appealBody());
        Long secondAppealId = extractLong(secondCreated, "data.appealId");
        secondCreated.then().statusCode(201).body("success", equalTo(true));
        assertTrace(secondKey, secondAppealId, 2);
    }

    @Test
    void concurrentRetryReturnsCreatedAndAlreadyReportedWithOneRow() throws Exception {
        String key = newIdempotencyKey();
        Map<String, Object> body = appealBody();
        CountDownLatch start = new CountDownLatch(1);
        ExecutorService executor = Executors.newFixedThreadPool(2);
        try {
            Future<Response> first = executor.submit(() -> {
                start.await();
                return postAppeal(key, body);
            });
            Future<Response> second = executor.submit(() -> {
                start.await();
                return postAppeal(key, body);
            });
            start.countDown();

            Response firstResponse = first.get(15, TimeUnit.SECONDS);
            Response secondResponse = second.get(15, TimeUnit.SECONDS);
            assertThat(java.util.List.of(firstResponse.statusCode(), secondResponse.statusCode()))
                    .containsExactlyInAnyOrder(201, 208);
            Long appealId = firstResponse.statusCode() == 201
                    ? extractLong(firstResponse, "data.appealId")
                    : extractLong(secondResponse, "data.appealId");
            assertTrace(key, appealId, 1);
        } finally {
            executor.shutdownNow();
        }
    }

    @Test
    void rejectedRequestDoesNotPoisonTheKeyForAValidRetry() {
        String key = newIdempotencyKey();
        postAppeal(key, Map.of("offenseId", offenseId))
                .then().statusCode(400);
        assertThat(historyCount(key)).isZero();
        assertThat(appealCount()).isZero();

        Response created = postAppeal(key, appealBody());
        Long appealId = extractLong(created, "data.appealId");
        created.then().statusCode(201);
        assertTrace(key, appealId, 1);
    }

    @Test
    void overlongKeyIsRejectedBeforeReservationAndBusinessInsert() {
        String key = "k".repeat(65);

        Response rejected = postAppeal(key, appealBody());

        rejected.then().statusCode(400).body("success", equalTo(false));
        assertThat(historyCount(key)).isZero();
        assertThat(appealCount()).isZero();
    }

    @Test
    void nonDuplicateIntegrityFailureIsNotReportedAs208AndRollsBackBusinessInsert() {
        String key = newIdempotencyKey();
        Map<String, Object> body = appealBody();
        body.put("appellantName", "x".repeat(1000));

        Response rejected = postAppeal(key, body);

        assertThat(rejected.statusCode()).isEqualTo(409);
        assertThat(rejected.statusCode()).isNotEqualTo(208);
        assertThat(historyCount(key)).isZero();
        assertThat(appealCount()).isZero();
    }

    private Response postAppeal(String key, Map<String, Object> body) {
        return authSpec(userToken)
                .header("Idempotency-Key", key)
                .body(body)
                .post("/api/appeals");
    }

    private Map<String, Object> appealBody() {
        return new HashMap<>(TestDataFactory.validAppeal(offenseId));
    }

    private void assertTrace(String key, Long appealId, int expectedAppeals) {
        assertThat(appealCount()).isEqualTo(expectedAppeals);
        assertThat(historyCount(key)).isOne();
        Map<String, Object> history = jdbcTemplate.queryForMap("""
                SELECT business_id, business_status, request_params
                FROM sys_request_history
                WHERE idempotency_key = ?
                """, key);
        assertThat(((Number) history.get("business_id")).longValue()).isEqualTo(appealId);
        assertThat(history.get("business_status")).isEqualTo("SUCCESS");
        assertThat(history.get("request_params")).isEqualTo("DONE");
    }

    private void assertAuthenticatedIdentity(Long appealId) {
        Map<String, Object> appeal = jdbcTemplate.queryForMap("""
                SELECT created_by, driver_id
                FROM appeal_record
                WHERE appeal_id = ?
                """, appealId);
        assertThat(appeal.get("created_by")).isEqualTo("testuser");
        assertThat(((Number) appeal.get("driver_id")).longValue()).isEqualTo(userDriverId);
    }

    private int appealCount() {
        return jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM appeal_record WHERE offense_id = ?", Integer.class, offenseId);
    }

    private int historyCount(String key) {
        return jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM sys_request_history WHERE idempotency_key = ?", Integer.class, key);
    }

    private Long createPrerequisiteOffense() {
        String adminToken = loginAsAdmin();
        Map<String, Object> vehicle = new HashMap<>(TestDataFactory.validVehicle(userDriverId));
        vehicle.put("ownerIdCard", "110101199001011234");
        Long vehicleId = extractLong(authSpec(adminToken)
                .header("Idempotency-Key", newIdempotencyKey())
                .body(vehicle)
                .post("/api/vehicles"), "data.vehicleId");
        Map<String, Object> offense = new HashMap<>(TestDataFactory.validOffense(userDriverId, vehicleId));
        offense.put("offenseCode", ensureOffenseCode());
        offense.put("offenseNumber", "EXP006-" + System.nanoTime());
        offense.put("processStatus", "Unprocessed");
        return extractLong(authSpec(adminToken)
                .header("Idempotency-Key", newIdempotencyKey())
                .body(offense)
                .post("/api/offenses"), "data.offenseId");
    }

    private String ensureOffenseCode() {
        String code = "EXP006_TEST";
        Integer tableCount = jdbcTemplate.queryForObject("""
                SELECT COUNT(*)
                FROM information_schema.tables
                WHERE table_schema = DATABASE() AND table_name = 'offense_type_dict'
                """, Integer.class);
        if (tableCount == null || tableCount == 0) {
            return "OSS-001";
        }
        jdbcTemplate.update("""
                INSERT INTO offense_type_dict (offense_code, offense_name, category)
                VALUES (?, 'EXP-006 test offense', 'Test')
                ON DUPLICATE KEY UPDATE offense_name = VALUES(offense_name)
                """, code);
        return code;
    }
}
