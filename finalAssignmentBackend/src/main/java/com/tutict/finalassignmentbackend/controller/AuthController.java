package com.tutict.finalassignmentbackend.controller;

import com.tutict.finalassignmentbackend.entity.SysUser;
import com.tutict.finalassignmentbackend.service.AuthWsService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.annotation.security.PermitAll;
import jakarta.annotation.security.RolesAllowed;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.scheduling.annotation.Async;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.Map;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.logging.Level;
import java.util.logging.Logger;

@RestController
@RequestMapping("/api/auth")
@Tag(name = "Authentication", description = "用户身份认证与注册接口")
public class AuthController {

    private static final Logger LOG = Logger.getLogger(AuthController.class.getName());
    private static final ExecutorService VIRTUAL_THREAD_EXECUTOR = Executors.newVirtualThreadPerTaskExecutor();

    private final AuthWsService authWsService;

    public AuthController(AuthWsService authWsService) {
        this.authWsService = authWsService;
    }

    @PostMapping("/login")
    @PermitAll
    @Async
    @Operation(
            summary = "用户登录",
            description = "允许用户通过用户名和密码登录，成功后返回携带角色信息的 JWT 令牌。"
    )
    @ApiResponses({
            @ApiResponse(
                    responseCode = "200",
                    description = "登录成功，返回包含令牌的结构化响应",
                    content = @Content(mediaType = "application/json",
                            schema = @Schema(type = "object",
                                    example = "{\"jwtToken\":\"<token>\",\"username\":\"admin\",\"roles\":[\"ROLE_ADMIN\"]}")))
            ,
            @ApiResponse(
                    responseCode = "400",
                    description = "请求参数缺失或无效",
                    content = @Content(mediaType = "application/json",
                            schema = @Schema(type = "object", example = "{\"error\":\"Username and password are required\"}")))
            ,
            @ApiResponse(
                    responseCode = "401",
                    description = "用户名或密码错误",
                    content = @Content(mediaType = "application/json",
                            schema = @Schema(type = "object", example = "{\"error\":\"Invalid credentials\"}")))
    })
    public CompletableFuture<ResponseEntity<Map<String, Object>>> login(
            @RequestBody
            @Parameter(description = "登录请求体，包含用户名和密码", required = true)
            AuthWsService.LoginRequest loginRequest) {
        if (loginRequest == null || loginRequest.getUsername() == null || loginRequest.getPassword() == null) {
            LOG.log(Level.WARNING, "Login request missing username or password");
            return CompletableFuture.completedFuture(
                    ResponseEntity.status(HttpStatus.BAD_REQUEST)
                            .body(Map.of("error", "Username and password are required")));
        }

        return CompletableFuture.supplyAsync(() -> {
            try {
                Map<String, Object> result = authWsService.login(loginRequest);
                LOG.log(Level.INFO, "Login succeeded for username: {0}", loginRequest.getUsername());
                return ResponseEntity.ok(result);
            } catch (Exception ex) {
                LOG.log(Level.SEVERE, "Login failed for username: {0}, error: {1}",
                        new Object[]{loginRequest.getUsername(), ex.getMessage()});
                return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                        .body(Map.of("error", ex.getMessage()));
            }
        }, VIRTUAL_THREAD_EXECUTOR);
    }

    @PostMapping("/register")
    @PermitAll
    @Async
    @Transactional
    @Operation(
            summary = "用户注册",
            description = "注册新用户并自动分配角色，支持幂等性保护。"
    )
    @ApiResponses({
            @ApiResponse(
                    responseCode = "201",
                    description = "注册成功",
                    content = @Content(mediaType = "application/json",
                            schema = @Schema(type = "object", example = "{\"status\":\"CREATED\"}")))
            ,
            @ApiResponse(
                    responseCode = "409",
                    description = "用户名已存在或重复请求",
                    content = @Content(mediaType = "application/json",
                            schema = @Schema(type = "object", example = "{\"error\":\"用户名已存在\"}")))
            ,
            @ApiResponse(
                    responseCode = "500",
                    description = "服务器内部错误",
                    content = @Content(mediaType = "application/json",
                            schema = @Schema(type = "object", example = "{\"error\":\"Internal server error\"}")))
    })
    public CompletableFuture<ResponseEntity<Map<String, String>>> registerUser(
            @RequestBody
            @Parameter(description = "注册请求体，包含用户名、密码、角色以及幂等键", required = true)
            AuthWsService.RegisterRequest registerRequest) {
        return CompletableFuture.supplyAsync(() -> {
                    try {
                        String status = authWsService.registerUser(registerRequest);
                        LOG.log(Level.INFO, "Register succeeded for username: {0}", registerRequest.getUsername());
                        return ResponseEntity.status(HttpStatus.CREATED)
                                .body(Map.of("status", status));
                    } catch (Exception ex) {
                        LOG.log(Level.WARNING, "Register failed for username: {0}, error: {1}",
                                new Object[]{registerRequest.getUsername(), ex.getMessage()});
                        return ResponseEntity.status(HttpStatus.CONFLICT)
                                .body(Map.of("error", ex.getMessage()));
                    }
                }, VIRTUAL_THREAD_EXECUTOR)
                .exceptionally(throwable -> {
                    LOG.log(Level.SEVERE, "Unexpected error in registerUser for username: {0}, error: {1}",
                            new Object[]{registerRequest.getUsername(), throwable.getMessage()});
                    return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                            .body(Map.of("error", "Internal server error"));
                });
    }

    @GetMapping("/users")
    @RolesAllowed({"SUPER_ADMIN", "ADMIN"})
    @SecurityRequirement(name = "bearerAuth")
    @Operation(
            summary = "获取全部系统用户",
            description = "仅管理员角色可查询系统中所有用户的基本信息。"
    )
    @ApiResponses({
            @ApiResponse(
                    responseCode = "200",
                    description = "查询成功",
                    content = @Content(mediaType = "application/json",
                            schema = @Schema(implementation = SysUser.class)))
            ,
            @ApiResponse(
                    responseCode = "403",
                    description = "无访问权限",
                    content = @Content(mediaType = "application/json",
                            schema = @Schema(type = "object", example = "{\"error\":\"Access denied\"}")))
    })
    public ResponseEntity<List<SysUser>> getAllUsers() {
        try {
            List<SysUser> users = authWsService.getAllUsers();
            LOG.log(Level.INFO, "Fetched {0} users", users.size());
            return ResponseEntity.ok(users);
        } catch (Exception ex) {
            LOG.log(Level.SEVERE, "GetAllUsers failed: {0}", ex.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(List.of());
        }
    }
}

