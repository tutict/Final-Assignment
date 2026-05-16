package com.tutict.finalassignmentbackend.integration.driver;

import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.anyOf;
import static org.hamcrest.Matchers.empty;
import static org.hamcrest.Matchers.equalTo;
import static org.hamcrest.Matchers.is;
import static org.hamcrest.Matchers.not;
import static org.hamcrest.Matchers.notNullValue;

import com.tutict.finalassignmentbackend.integration.BaseIntegrationTest;
import com.tutict.finalassignmentbackend.integration.TestDataFactory;
import io.restassured.response.Response;
import java.util.Map;
import java.util.stream.Collectors;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.MethodOrderer;
import org.junit.jupiter.api.Order;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.TestMethodOrder;

@DisplayName("驾驶员与车辆管理业务流集成测试")
@TestMethodOrder(MethodOrderer.OrderAnnotation.class)
class DriverVehicleIntegrationTest extends BaseIntegrationTest {

    private String adminToken;

    @BeforeEach
    void setUp() {
        adminToken = loginAsAdmin();
    }

    @Test
    @Order(1)
    @DisplayName("创建驾驶员：LocalDate 字段使用 yyyy-MM-dd 格式成功")
    void create_driver_with_local_date_format_succeeds() {
        authSpec(adminToken)
            .header("Idempotency-Key", newIdempotencyKey())
            .body(Map.of(
                "name", "李测试",
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
    @DisplayName("创建驾驶员：LocalDate 字段传 ISO datetime 格式（含时间）返回 400")
    void create_driver_with_datetime_in_date_field_returns_400() {
        authSpec(adminToken)
            .header("Idempotency-Key", newIdempotencyKey())
            .body(Map.of(
                "name", "错误格式测试",
                "licenseNumber", "ERR" + System.currentTimeMillis(),
                "birthdate", "1985-05-15T00:00:00"
            ))
            .post("/api/drivers")
            .then()
            .statusCode(400);
    }

    @Test
    @Order(3)
    @DisplayName("驾驶员列表：支持分页，不返回全量数据")
    void driver_list_supports_pagination() {
        for (int i = 0; i < 3; i++) {
            authSpec(adminToken)
                .header("Idempotency-Key", newIdempotencyKey())
                .body(Map.of(
                    "name", "分页测试" + i,
                    "licenseNumber", "PAGE" + i + System.currentTimeMillis(),
                    "birthdate", "1990-01-01",
                    "firstLicenseDate", "2010-01-01",
                    "issueDate", "2020-01-01",
                    "expiryDate", "2030-01-01"
                ))
                .post("/api/drivers");
        }

        Response resp = authSpec(adminToken)
            .queryParam("page", 0)
            .queryParam("size", 2)
            .get("/api/drivers");

        resp.then()
            .statusCode(200)
            .body("success", equalTo(true));

        Integer total = resp.path("data.total");
        assertThat(total)
            .withFailMessage("后端仍返回全量 List 而非分页结构")
            .isNotNull();
    }

    @Test
    @Order(4)
    @DisplayName("驾驶员搜索：按姓名模糊搜索返回匹配结果")
    void driver_search_by_name_returns_matches() {
        String uniqueName = "搜索测试" + System.currentTimeMillis();
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

        authSpec(adminToken)
            .queryParam("name", "搜索测试")
            .get("/api/drivers/search")
            .then()
            .statusCode(200)
            .body("data", not(empty()));
    }

    @Test
    @Order(5)
    @DisplayName("创建车辆：LocalDate 字段格式正确，关联驾驶员 ID")
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
    @DisplayName("车辆自动补全：按车牌前缀返回建议列表")
    void vehicle_autocomplete_returns_suggestions() {
        Long driverId = createTestDriver();
        String plate = "京A" + System.currentTimeMillis() % 10000;

        authSpec(adminToken)
            .header("Idempotency-Key", newIdempotencyKey())
            .body(TestDataFactory.validVehicle(driverId).entrySet()
                .stream().collect(Collectors.toMap(
                    Map.Entry::getKey,
                    e -> e.getKey().equals("licensePlate") ? plate : e.getValue()
                )))
            .post("/api/vehicles");

        authSpec(adminToken)
            .queryParam("prefix", plate.substring(0, 3))
            .get("/api/vehicles/autocomplete")
            .then()
            .statusCode(200)
            .body("$", not(empty()));
    }

    private Long createTestDriver() {
        return authSpec(adminToken)
            .header("Idempotency-Key", newIdempotencyKey())
            .body(TestDataFactory.validDriver())
            .post("/api/drivers")
            .then().extract().path("data.driverId");
    }
}
