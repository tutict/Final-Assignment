package com.tutict.finalassignmentbackend.controller;

import com.tutict.finalassignmentbackend.entity.UserManagement;
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
@Tag(name = "Authentication", description = "APIs for user authentication and management")
public class AuthController {

    private static final Logger logger = Logger.getLogger(AuthController.class.getName());

    private static final ExecutorService virtualThreadExecutor = Executors.newVirtualThreadPerTaskExecutor();

    private final AuthWsService authWsService;

    public AuthController(AuthWsService authWsService) {
        this.authWsService = authWsService;
    }

    @PostMapping("/login")
    @PermitAll
    @Async
    @Operation(
            summary = "用户登录",
            description = "允许用户通过用户名和密码登录，成功后返回 JWT 令牌。异步处理请求以提高性能。"
    )
    @ApiResponses({
            @ApiResponse(
                    responseCode = "200",
                    description = "登录成功，返回包含 JWT 令牌和其他用户信息的 Map",
                    content = @Content(
                            mediaType = "application/json",
                            schema = @Schema(type = "object", example = "{\"jwtToken\": \"<token>\", \"username\": \"<username>\"}")
                    )
            ),
            @ApiResponse(
                    responseCode = "400",
                    description = "无效的请求，用户名或密码为空",
                    content = @Content(
                            mediaType = "application/json",
                            schema = @Schema(type = "object", example = "{\"error\": \"Username and password are required\"}")
                    )
            ),
            @ApiResponse(
                    responseCode = "401",
                    description = "登录失败，用户名或密码错误",
                    content = @Content(
                            mediaType = "application/json",
                            schema = @Schema(type = "object", example = "{\"error\": \"Invalid credentials\"}")
                    )
            )
    })
    public CompletableFuture<ResponseEntity<Map<String, Object>>> login(
            @RequestBody
            @Parameter(description = "登录请求，包含用户名和密码", required = true)
            AuthWsService.LoginRequest loginRequest) {
        if (loginRequest == null || loginRequest.getUsername() == null || loginRequest.getPassword() == null) {
            logger.log(Level.SEVERE, "Login request invalid: null or missing username/password");
            return CompletableFuture.completedFuture(
                    ResponseEntity.status(HttpStatus.BAD_REQUEST).body(Map.of("error", "Username and password are required")));
        }
        return CompletableFuture.supplyAsync(() -> {
            try {
                Map<String, Object> result = authWsService.login(loginRequest);
                if (result.containsKey("jwtToken")) {
                    logger.log(Level.INFO, "Login succeeded for username: {0}", loginRequest.getUsername());
                    return ResponseEntity.ok(result);
                } else {
                    logger.log(Level.WARNING, "Login failed for username: {0}", loginRequest.getUsername());
                    return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(result);
                }
            } catch (Exception e) {
                logger.log(Level.SEVERE, "Login failed for username: {0}, error: {1}", new Object[]{loginRequest.getUsername(), e.getMessage()});
                return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(Map.of("error", e.getMessage()));
            }
        }, virtualThreadExecutor);
    }

    @PostMapping("/register")
    @PermitAll
    @Async
    @Transactional
    @Operation(
            summary = "用户注册",
            description = "允许用户注册新账户，异步处理并在事务中执行。成功后返回注册状态。"
    )
    @ApiResponses({
            @ApiResponse(
                    responseCode = "201",
                    description = "注册成功，返回注册状态",
                    content = @Content(
                            mediaType = "application/json",
                            schema = @Schema(type = "object", example = "{\"status\": \"User registered successfully\"}")
                    )
            ),
            @ApiResponse(
                    responseCode = "409",
                    description = "注册失败，用户名已存在或其他冲突",
                    content = @Content(
                            mediaType = "application/json",
                            schema = @Schema(type = "object", example = "{\"error\": \"Username already exists\"}")
                    )
            ),
            @ApiResponse(
                    responseCode = "500",
                    description = "服务器内部错误",
                    content = @Content(
                            mediaType = "application/json",
                            schema = @Schema(type = "object", example = "{\"error\": \"Internal server error\"}")
                    )
            )
    })
    public CompletableFuture<ResponseEntity<Map<String, String>>> registerUser(
            @RequestBody
            @Parameter(description = "注册请求，包含用户名、密码和其他用户信息", required = true)
            AuthWsService.RegisterRequest registerRequest) {
        logger.log(Level.INFO, "Received register request for username: {0}", registerRequest.getUsername());
        return CompletableFuture.supplyAsync(() -> {
                    try {
                        String res = authWsService.registerUser(registerRequest);
                        logger.log(Level.INFO, "Register succeeded for username: {0}", registerRequest.getUsername());
                        return ResponseEntity.status(HttpStatus.CREATED)
                                .header("Content-Type", "application/json")
                                .body(Map.of("status", res));
                    } catch (Exception e) {
                        logger.log(Level.SEVERE, "Register failed for username: {0}, error: {1}", new Object[]{registerRequest.getUsername(), e.getMessage()});
                        return ResponseEntity.status(HttpStatus.CONFLICT)
                                .header("Content-Type", "application/json")
                                .body(Map.of("error", e.getMessage()));
                    }
                }, virtualThreadExecutor)
                .exceptionally(throwable -> {
                    logger.log(Level.SEVERE, "Unexpected error in registerUser for username: {0}, error: {1}",
                            new Object[]{registerRequest.getUsername(), throwable.getMessage()});
                    return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                            .header("Content-Type", "application/json")
                            .body(Map.of("error", "Internal server error"));
                });
    }

    @GetMapping("/users")
    @RolesAllowed("ADMIN")
    @SecurityRequirement(name = "bearerAuth")
    @Operation(
            summary = "获取所有用户",
            description = "管理员获取所有用户信息的列表，仅限 ADMIN 角色访问。"
    )
    @ApiResponses({
            @ApiResponse(
                    responseCode = "200",
                    description = "成功返回用户列表",
                    content = @Content(
                            mediaType = "application/json",
                            schema = @Schema(implementation = UserManagement.class)
                    )
            ),
            @ApiResponse(
                    responseCode = "500",
                    description = "服务器内部错误",
                    content = @Content(
                            mediaType = "application/json",
                            schema = @Schema(type = "array", example = "[]")
                    )
            ),
            @ApiResponse(
                    responseCode = "403",
                    description = "无权限访问，需 ADMIN 角色",
                    content = @Content(
                            mediaType = "application/json",
                            schema = @Schema(type = "object", example = "{\"error\": \"Access denied\"}")
                    )
            )
    })
    public ResponseEntity<List<UserManagement>> getAllUsers() {
        try {
            List<UserManagement> users = authWsService.getAllUsers();
            logger.log(Level.INFO, "Fetched {0} users successfully", users.size());
            return ResponseEntity.ok(users);
        } catch (Exception e) {
            logger.log(Level.SEVERE, "GetAllUsers failed: {0}", e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(List.of());
        }
    }
}