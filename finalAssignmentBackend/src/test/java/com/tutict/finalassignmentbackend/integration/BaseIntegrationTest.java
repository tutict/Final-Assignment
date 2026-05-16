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
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.testcontainers.containers.KafkaContainer;
import org.testcontainers.containers.MySQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;
import org.testcontainers.utility.DockerImageName;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@ActiveProfiles("test")
@Testcontainers
@TestMethodOrder(MethodOrderer.OrderAnnotation.class)
public abstract class BaseIntegrationTest {

    @LocalServerPort
    protected int port;

    @Autowired
    protected ObjectMapper objectMapper;

    // -- Testcontainers -------------------------------------------------------
    @Container
    static MySQLContainer<?> mysql = new MySQLContainer<>("mysql:8.0")
        .withDatabaseName("testdb")
        .withUsername("test")
        .withPassword("test");

    @Container
    static KafkaContainer kafka = new KafkaContainer(
        DockerImageName.parse("confluentinc/cp-kafka:7.5.0"));

    @DynamicPropertySource
    static void overrideProperties(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", mysql::getJdbcUrl);
        registry.add("spring.datasource.username", mysql::getUsername);
        registry.add("spring.datasource.password", mysql::getPassword);
        registry.add("spring.kafka.bootstrap-servers", kafka::getBootstrapServers);
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
