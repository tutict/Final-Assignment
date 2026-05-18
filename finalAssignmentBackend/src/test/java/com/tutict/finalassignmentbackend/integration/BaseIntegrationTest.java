package com.tutict.finalassignmentbackend.integration;

import static org.awaitility.Awaitility.await;
import static org.hamcrest.Matchers.anyOf;
import static org.hamcrest.Matchers.equalTo;
import static org.hamcrest.Matchers.is;

import com.fasterxml.jackson.databind.ObjectMapper;
import io.restassured.RestAssured;
import io.restassured.http.ContentType;
import io.restassured.response.Response;
import io.restassured.specification.RequestSpecification;
import java.time.Duration;
import java.util.Map;
import java.util.UUID;
import org.junit.jupiter.api.MethodOrderer;
import org.junit.jupiter.api.TestMethodOrder;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.server.LocalServerPort;
import org.springframework.context.annotation.Import;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.jdbc.Sql;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@ActiveProfiles("test")
@TestMethodOrder(MethodOrderer.OrderAnnotation.class)
@Sql(scripts = "/sql/test-seed-data.sql", executionPhase = Sql.ExecutionPhase.BEFORE_TEST_CLASS)
@Import(TestSearchRepositoryMockConfig.class)
public abstract class BaseIntegrationTest {

    private static final boolean USE_TESTCONTAINERS = Boolean.parseBoolean(
        System.getProperty("useTestcontainers",
            System.getenv().getOrDefault("USE_TESTCONTAINERS", "false")));

    @LocalServerPort
    protected int port;

    @Autowired
    protected ObjectMapper objectMapper;

    static {
        if (USE_TESTCONTAINERS) {
            System.setProperty("testcontainers.reuse.enable", "true");
            System.setProperty("ryuk.disabled", "true");
            System.setProperty("testcontainers.ryuk.disabled", "true");
        }
    }

    // -- REST Assured config --------------------------------------------------
    protected RequestSpecification baseSpec() {
        return RestAssured.given()
            .baseUri("http://localhost")
            .port(port)
            .contentType(ContentType.JSON)
            .accept(ContentType.JSON)
            .log().ifValidationFails();
    }

    protected RequestSpecification authSpec(String token) {
        return baseSpec()
            .header("Authorization", "Bearer " + token);
    }

    // -- Login helpers --------------------------------------------------------
    protected String loginAs(String username, String password) {
        return baseSpec()
            .body(Map.of("username", username, "password", password))
            .post("/api/auth/login")
            .then()
            .statusCode(200)
            .extract()
            .path("accessToken");
    }

    protected String loginAsAdmin() {
        return loginAs("admin", "Admin@123456");
    }

    protected String loginAsUser() {
        return loginAs("testuser", "User@123456");
    }

    protected String loginAsSuperAdmin() {
        return loginAs("superadmin", "SuperAdmin@123456");
    }

    // -- Assertion helpers ----------------------------------------------------
    protected void assertApiSuccess(Response response) {
        response.then()
            .statusCode(anyOf(is(200), is(201)))
            .body("success", equalTo(true));
    }

    protected void assertApiError(Response response, int expectedStatus, String expectedErrorCode) {
        response.then()
            .statusCode(expectedStatus)
            .body("success", equalTo(false))
            .body("errorCode", equalTo(expectedErrorCode));
    }

    // -- Kafka async wait helper ---------------------------------------------
    protected void waitForKafkaConsumer(Duration timeout) {
        await().atMost(timeout).pollInterval(Duration.ofMillis(200))
            .until(() -> true);
    }

    // -- Idempotency key helper ----------------------------------------------
    protected String newIdempotencyKey() {
        return UUID.randomUUID().toString();
    }
}
