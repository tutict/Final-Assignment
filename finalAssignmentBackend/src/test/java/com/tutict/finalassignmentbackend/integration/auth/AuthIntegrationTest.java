package com.tutict.finalassignmentbackend.integration.auth;

import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.anyOf;
import static org.hamcrest.Matchers.empty;
import static org.hamcrest.Matchers.equalTo;
import static org.hamcrest.Matchers.is;
import static org.hamcrest.Matchers.not;
import static org.hamcrest.Matchers.notNullValue;
import static org.hamcrest.Matchers.nullValue;

import com.tutict.finalassignmentbackend.integration.BaseIntegrationTest;
import io.restassured.response.Response;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;
import java.util.stream.Collectors;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Order;
import org.junit.jupiter.api.Test;

@DisplayName("认证业务流集成测试")
class AuthIntegrationTest extends BaseIntegrationTest {

    @Test
    @Order(1)
    @DisplayName("正常登录：返回 accessToken + refreshToken + 用户身份信息")
    void login_success_returns_tokens_and_identity() {
        Response resp = baseSpec()
            .body(Map.of("username", "admin", "password", "Admin@123456"))
            .post("/api/auth/login");

        resp.then()
            .statusCode(200)
            .body("accessToken", notNullValue())
            .body("refreshToken", notNullValue())
            .body("authUserId", notNullValue())
            .body("roles", not(empty()))
            .body("password", nullValue())
            .body("salt", nullValue());
    }

    @Test
    @Order(2)
    @DisplayName("登录失败：用户名或密码错误返回 401，且格式是 ApiResponse")
    void login_wrong_password_returns_401_with_api_response() {
        Response resp = baseSpec()
            .body(Map.of("username", "admin", "password", "WrongPassword"))
            .post("/api/auth/login");

        resp.then()
            .statusCode(401)
            .body("success", equalTo(false))
            .body("message", notNullValue());
    }

    @Test
    @Order(3)
    @DisplayName("登录时不携带旧 Authorization header 也能成功（黑名单 token 不阻断登录）")
    void login_without_old_token_succeeds() {
        String token = loginAsAdmin();

        authSpec(token).post("/api/auth/logout").then().statusCode(anyOf(is(200), is(204)));

        baseSpec()
            .body(Map.of("username", "admin", "password", "Admin@123456"))
            .post("/api/auth/login")
            .then()
            .statusCode(200)
            .body("accessToken", notNullValue());
    }

    @Test
    @Order(4)
    @DisplayName("Refresh：用有效 refreshToken 换取新 accessToken")
    void refresh_with_valid_refresh_token_returns_new_tokens() {
        String refreshToken = baseSpec()
            .body(Map.of("username", "admin", "password", "Admin@123456"))
            .post("/api/auth/login")
            .then().extract().path("refreshToken");

        assertThat(refreshToken).isNotNull();

        Response resp = baseSpec()
            .body(Map.of("refreshToken", refreshToken))
            .post("/api/auth/refresh");

        resp.then()
            .statusCode(200)
            .body("success", equalTo(true))
            .body("data.accessToken", notNullValue())
            .body("data.refreshToken", notNullValue());
    }

    @Test
    @Order(5)
    @DisplayName("Refresh：旧 refreshToken 在 rotate 后失效")
    void refresh_token_rotation_invalidates_old_token() {
        String refreshToken = baseSpec()
            .body(Map.of("username", "admin", "password", "Admin@123456"))
            .post("/api/auth/login")
            .then().extract().path("refreshToken");

        baseSpec()
            .body(Map.of("refreshToken", refreshToken))
            .post("/api/auth/refresh")
            .then().statusCode(200);

        baseSpec()
            .body(Map.of("refreshToken", refreshToken))
            .post("/api/auth/refresh")
            .then()
            .statusCode(anyOf(is(401), is(400)))
            .body("success", equalTo(false));
    }

    @Test
    @Order(6)
    @DisplayName("登出：accessToken 进入黑名单，后续请求返回 401")
    void logout_blacklists_access_token() {
        String token = loginAsAdmin();

        authSpec(token)
            .post("/api/auth/logout")
            .then().statusCode(anyOf(is(200), is(204)));

        authSpec(token)
            .get("/api/users")
            .then()
            .statusCode(401)
            .body("success", equalTo(false))
            .body("errorCode", equalTo("UNAUTHORIZED"));
    }

    @Test
    @Order(7)
    @DisplayName("/api/auth/me：返回完整用户画像，不含敏感字段")
    void get_current_user_profile_excludes_sensitive_fields() {
        String token = loginAsAdmin();

        authSpec(token)
            .get("/api/auth/me")
            .then()
            .statusCode(200)
            .body("success", equalTo(true))
            .body("data.authUserId", notNullValue())
            .body("data.username", notNullValue())
            .body("data.roles", not(empty()))
            .body("data.password", nullValue())
            .body("data.salt", nullValue());
    }

    @Test
    @Order(8)
    @DisplayName("Regular user profile is linked to an independent driver profile")
    void regular_user_profile_links_to_driver_profile() {
        String userToken = loginAsUser();

        authSpec(userToken)
            .get("/api/auth/me")
            .then()
            .statusCode(200)
            .body("success", equalTo(true))
            .body("data.authUserId", notNullValue())
            .body("data.driverId", notNullValue())
            .body("data.driverName", notNullValue());
    }

    @Test
    @Order(9)
    @DisplayName("未认证请求受保护接口返回 401（ApiResponse 格式）")
    void unauthenticated_request_returns_401_in_api_response_format() {
        baseSpec()
            .get("/api/offenses")
            .then()
            .statusCode(401)
            .body("success", equalTo(false))
            .body("errorCode", anyOf(equalTo("UNAUTHORIZED"), equalTo("UNAUTHENTICATED")));
    }

    @Test
    @Order(10)
    @DisplayName("普通用户访问管理员接口返回 403（不跳登录）")
    void regular_user_access_admin_endpoint_returns_403_not_redirect() {
        String userToken = loginAsUser();

        Response resp = authSpec(userToken)
            .get("/api/users");

        resp.then()
            .statusCode(403)
            .body("success", equalTo(false))
            .body("errorCode", equalTo("FORBIDDEN"))
            .header("Location", nullValue());
    }

    @Test
    @Order(11)
    @DisplayName("并发 Refresh：多个并发请求只成功一次，不踢用户下线")
    void concurrent_refresh_does_not_kick_user_offline() throws Exception {
        String refreshToken = baseSpec()
            .body(Map.of("username", "admin", "password", "Admin@123456"))
            .post("/api/auth/login")
            .then().extract().path("refreshToken");

        ExecutorService executor = Executors.newFixedThreadPool(5);
        List<Future<Integer>> futures = new ArrayList<>();

        for (int i = 0; i < 5; i++) {
            futures.add(executor.submit(() ->
                baseSpec()
                    .body(Map.of("refreshToken", refreshToken))
                    .post("/api/auth/refresh")
                    .statusCode()
            ));
        }
        executor.shutdown();
        executor.awaitTermination(10, TimeUnit.SECONDS);

        List<Integer> codes = futures.stream()
            .map(f -> {
                try {
                    return f.get();
                } catch (Exception e) {
                    return -1;
                }
            })
            .collect(Collectors.toList());

        long successCount = codes.stream().filter(c -> c == 200).count();
        assertThat(successCount).isEqualTo(1);

        codes.stream()
            .filter(c -> c != 200)
            .forEach(c -> assertThat(c).isIn(400, 401));
    }
}
