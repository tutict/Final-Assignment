package com.tutict.finalassignmentbackend.integration.driver;

import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.anyOf;
import static org.hamcrest.Matchers.equalTo;
import static org.hamcrest.Matchers.is;
import static org.hamcrest.Matchers.notNullValue;

import com.fasterxml.jackson.databind.JsonNode;
import com.tutict.finalassignmentbackend.integration.BaseIntegrationTest;
import com.tutict.finalassignmentbackend.integration.TestDataFactory;
import java.net.URI;
import java.net.URLEncoder;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.util.Map;
import java.util.stream.Collectors;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.MethodOrderer;
import org.junit.jupiter.api.Order;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.TestMethodOrder;

@DisplayName("Driver and vehicle integration flow")
@TestMethodOrder(MethodOrderer.OrderAnnotation.class)
class DriverVehicleIntegrationTest extends BaseIntegrationTest {

    private String adminToken;

    @BeforeEach
    void setUp() {
        adminToken = loginAsAdmin();
    }

    @Test
    @Order(1)
    @DisplayName("Create driver accepts yyyy-MM-dd LocalDate fields")
    void create_driver_with_local_date_format_succeeds() {
        authSpec(adminToken)
            .header("Idempotency-Key", newIdempotencyKey())
            .body(Map.of(
                "name", "Driver" + System.currentTimeMillis(),
                "licenseNumber", "DRV" + System.currentTimeMillis(),
                "phoneNumber", "13900139000",
                "birthdate", "1985-05-15",
                "firstLicenseDate", "2005-09-01",
                "issueDate", "2020-09-01",
                "expiryDate", "2030-09-01"
            ))
            .post("/api/drivers")
            .then()
            .statusCode(anyOf(is(200), is(201)))
            .body("success", equalTo(true))
            .body("data.driverId", notNullValue());
    }

    @Test
    @Order(2)
    @DisplayName("Create driver rejects datetime values in LocalDate fields")
    void create_driver_with_datetime_in_date_field_returns_400() {
        authSpec(adminToken)
            .header("Idempotency-Key", newIdempotencyKey())
            .body(Map.of(
                "name", "InvalidDateDriver",
                "licenseNumber", "ERR" + System.currentTimeMillis(),
                "birthdate", "1985-05-15T00:00:00"
            ))
            .post("/api/drivers")
            .then()
            .statusCode(400);
    }

    @Test
    @Order(3)
    @DisplayName("Driver list supports pagination envelope")
    void driver_list_supports_pagination() throws Exception {
        for (int i = 0; i < 3; i++) {
            authSpec(adminToken)
                .header("Idempotency-Key", newIdempotencyKey())
                .body(Map.of(
                    "name", "PagedDriver" + i + System.currentTimeMillis(),
                    "licenseNumber", "PAGE" + i + System.currentTimeMillis(),
                    "birthdate", "1990-01-01",
                    "firstLicenseDate", "2010-01-01",
                    "issueDate", "2020-01-01",
                    "expiryDate", "2030-01-01"
                ))
                .post("/api/drivers");
        }

        JsonNode body = getJson("/api/drivers?page=0&size=2");
        assertThat(body.path("success").asBoolean()).isTrue();
        assertThat(body.path("data").path("total").asInt()).isGreaterThanOrEqualTo(3);
    }

    @Test
    @Order(4)
    @DisplayName("Driver search by name returns matches")
    void driver_search_by_name_returns_matches() throws Exception {
        String uniqueName = "SearchDriver" + System.currentTimeMillis();
        authSpec(adminToken)
            .header("Idempotency-Key", newIdempotencyKey())
            .body(Map.of(
                "name", uniqueName,
                "licenseNumber", "SCH" + System.currentTimeMillis(),
                "birthdate", "1990-01-01",
                "firstLicenseDate", "2010-01-01",
                "issueDate", "2020-01-01",
                "expiryDate", "2030-01-01"
            ))
            .post("/api/drivers");

        JsonNode body = getJson("/api/drivers/search?name="
            + URLEncoder.encode("SearchDriver", StandardCharsets.UTF_8));
        assertThat(body.path("success").asBoolean()).isTrue();
        assertThat(body.path("data")).isNotEmpty();
    }

    @Test
    @Order(5)
    @DisplayName("Create vehicle echoes associated driver id")
    void create_vehicle_with_driver_association() {
        Long driverId = createTestDriver();

        authSpec(adminToken)
            .header("Idempotency-Key", newIdempotencyKey())
            .body(TestDataFactory.validVehicle(driverId))
            .post("/api/vehicles")
            .then()
            .statusCode(anyOf(is(200), is(201)))
            .body("success", equalTo(true))
            .body("data.vehicleId", notNullValue())
            .body("data.driverId", equalTo(driverId.intValue()));
    }

    @Test
    @Order(6)
    @DisplayName("Vehicle autocomplete returns license plate suggestions")
    void vehicle_autocomplete_returns_suggestions() throws Exception {
        Long driverId = createTestDriver();
        String plate = "PLT" + System.currentTimeMillis() % 10000;

        authSpec(adminToken)
            .header("Idempotency-Key", newIdempotencyKey())
            .body(TestDataFactory.validVehicle(driverId).entrySet()
                .stream().collect(Collectors.toMap(
                    Map.Entry::getKey,
                    e -> e.getKey().equals("licensePlate") ? plate : e.getValue()
                )))
            .post("/api/vehicles");

        JsonNode body = getJson("/api/vehicles/autocomplete?prefix="
            + URLEncoder.encode(plate.substring(0, 3), StandardCharsets.UTF_8));
        assertThat(body.path("success").asBoolean()).isTrue();
        assertThat(body.path("data")).isNotEmpty();
    }

    private Long createTestDriver() {
        Number id = authSpec(adminToken)
            .header("Idempotency-Key", newIdempotencyKey())
            .body(TestDataFactory.validDriver())
            .post("/api/drivers")
            .then()
            .extract()
            .path("data.driverId");
        return id.longValue();
    }

    private JsonNode getJson(String pathAndQuery) throws Exception {
        HttpResponse<String> response = HttpClient.newHttpClient()
            .send(HttpRequest.newBuilder()
                    .uri(URI.create("http://localhost:" + port + pathAndQuery))
                    .header("Authorization", "Bearer " + adminToken)
                    .header("Accept", "application/json")
                    .GET()
                    .build(),
                HttpResponse.BodyHandlers.ofString());
        assertThat(response.statusCode()).isEqualTo(200);
        return objectMapper.readTree(response.body());
    }
}
