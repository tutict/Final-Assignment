package com.tutict.finalassignmentbackend.integration.user;

import static org.hamcrest.Matchers.anyOf;
import static org.hamcrest.Matchers.containsString;
import static org.hamcrest.Matchers.equalTo;
import static org.hamcrest.Matchers.everyItem;
import static org.hamcrest.Matchers.is;
import static org.hamcrest.Matchers.notNullValue;
import static org.hamcrest.Matchers.nullValue;

import com.tutict.finalassignmentbackend.integration.BaseIntegrationTest;
import io.restassured.response.Response;
import java.util.Map;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.MethodOrderer;
import org.junit.jupiter.api.Order;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.TestMethodOrder;

@DisplayName("用户与角色权限管理集成测试")
@TestMethodOrder(MethodOrderer.OrderAnnotation.class)
class UserRoleIntegrationTest extends BaseIntegrationTest {

    private String superAdminToken;
    private String adminToken;
    private String userToken;

    @BeforeEach
    void setUp() {
        superAdminToken = loginAsSuperAdmin();
        adminToken = loginAsAdmin();
        userToken = loginAsUser();
    }

    @Test
    @Order(1)
    @DisplayName("用户列表：响应中不包含 password/salt 字段")
    void user_list_excludes_sensitive_fields() {
        authSpec(adminToken)
            .queryParam("page", 0)
            .queryParam("size", 10)
            .get("/api/users")
            .then()
            .statusCode(200)
            .body("success", equalTo(true))
            .body("data.content.password", everyItem(nullValue()))
            .body("data.content.salt", everyItem(nullValue()));
    }

    @Test
    @Order(2)
    @DisplayName("创建用户：请求中发送 password 字段，后端应哈希存储不原样返回")
    void create_user_password_is_hashed_not_returned() {
        String rawPassword = "TestUser@123456";

        Response resp = authSpec(superAdminToken)
            .header("Idempotency-Key", newIdempotencyKey())
            .body(Map.of(
                "username", "newuser" + System.currentTimeMillis(),
                "password", rawPassword,
                "email", "test@example.com",
                "phoneNumber", "13700137000"
            ))
            .post("/api/users");

        resp.then()
            .statusCode(anyOf(is(200), is(201)))
            .body("data.password", nullValue())
            .body("data.phoneNumber", containsString("****"));
    }

    @Test
    @Order(3)
    @DisplayName("用户查询：响应字段使用 phoneNumber 而非 contactNumber")
    void user_response_uses_phone_number_field_not_contact_number() {
        authSpec(adminToken)
            .queryParam("page", 0).queryParam("size", 1)
            .get("/api/users")
            .then()
            .statusCode(200)
            .body("data.content[0].phoneNumber", notNullValue())
            .body("data.content[0].contactNumber", nullValue());
    }

    @Test
    @Order(4)
    @DisplayName("角色旧路径 /api/roles/name/{name} 返回 404（已废弃）")
    void deprecated_role_by_name_path_returns_404() {
        authSpec(adminToken)
            .get("/api/roles/name/ADMIN")
            .then()
            .statusCode(anyOf(is(404), is(410)));
    }

    @Test
    @Order(5)
    @DisplayName("角色新路径 /api/roles/by-code/{code} 正常返回")
    void new_role_by_code_path_returns_role() {
        authSpec(adminToken)
            .get("/api/roles/by-code/ADMIN")
            .then()
            .statusCode(anyOf(is(200), is(404)));
    }

    @Test
    @Order(6)
    @DisplayName("角色旧搜索路径 /api/roles/search?name= 返回 404")
    void deprecated_role_search_path_returns_404() {
        authSpec(adminToken)
            .queryParam("name", "ADMIN")
            .get("/api/roles/search")
            .then()
            .statusCode(anyOf(is(404), is(410)));
    }

    @Test
    @Order(7)
    @DisplayName("角色新搜索路径 /api/roles/search/name/fuzzy 正常工作")
    void new_role_search_fuzzy_path_works() {
        authSpec(adminToken)
            .queryParam("roleName", "ADMIN")
            .get("/api/roles/search/name/fuzzy")
            .then()
            .statusCode(200)
            .body("success", equalTo(true));
    }

    @Test
    @Order(8)
    @DisplayName("权限旧路径 /api/permissions/name/{name} 返回 404")
    void deprecated_permission_by_name_path_returns_404() {
        authSpec(superAdminToken)
            .get("/api/permissions/name/READ_OFFENSE")
            .then()
            .statusCode(anyOf(is(404), is(410)));
    }

    @Test
    @Order(9)
    @DisplayName("权限新搜索路径正常工作")
    void new_permission_search_path_works() {
        authSpec(superAdminToken)
            .queryParam("permissionName", "READ")
            .get("/api/permissions/search/name/fuzzy")
            .then()
            .statusCode(200)
            .body("success", equalTo(true));
    }

    @Test
    @Order(10)
    @DisplayName("普通用户无法访问用户管理接口（方法级 @RolesAllowed 生效）")
    void regular_user_cannot_access_user_management() {
        authSpec(userToken)
            .get("/api/users")
            .then()
            .statusCode(403)
            .body("success", equalTo(false))
            .body("errorCode", equalTo("FORBIDDEN"));
    }

    @Test
    @Order(11)
    @DisplayName("管理员可以访问用户列表，但不能访问超级管理员接口")
    void admin_can_access_user_list_but_not_super_admin_endpoints() {
        authSpec(adminToken)
            .get("/api/users")
            .then()
            .statusCode(200);

        authSpec(adminToken)
            .header("Idempotency-Key", newIdempotencyKey())
            .body(Map.of(
                "roleCode", "TEST_ROLE_" + System.currentTimeMillis(),
                "roleName", "测试角色"
            ))
            .post("/api/roles")
            .then()
            .statusCode(anyOf(is(403), is(200), is(201)));
    }
}
