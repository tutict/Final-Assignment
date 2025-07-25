package com.tutict.finalassignmentbackend.controller;

import com.tutict.finalassignmentbackend.entity.UserManagement;
import com.tutict.finalassignmentbackend.service.UserManagementService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;

import java.net.URLDecoder;
import java.nio.charset.StandardCharsets;
import java.security.Principal;
import java.util.Collections;
import java.util.List;
import java.util.logging.Level;

@RestController
@RequestMapping("/api/users")
@SecurityRequirement(name = "bearerAuth")
@Tag(name = "User Management", description = "APIs for managing user records")
public class UserManagementController {

    private static final Logger logger = LoggerFactory.getLogger(UserManagementController.class);
    private final UserManagementService userManagementService;

    @Autowired
    public UserManagementController(UserManagementService userManagementService) {
        this.userManagementService = userManagementService;
    }

    @PostMapping
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(
            summary = "创建用户记录",
            description = "管理员创建新的用户记录，仅限 ADMIN 角色。需要提供幂等键以防止重复提交。如果用户名已存在，将返回冲突状态。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "201", description = "用户记录创建成功"),
            @ApiResponse(responseCode = "400", description = "无效的输入参数或幂等键冲突"),
            @ApiResponse(responseCode = "403", description = "无权限访问，仅限 ADMIN 角色"),
            @ApiResponse(responseCode = "409", description = "用户名已存在"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<Void> createUser(
            @RequestBody @Parameter(description = "用户记录的详细信息", required = true) UserManagement user,
            @RequestParam @Parameter(description = "幂等键，用于防止重复提交", required = true) String idempotencyKey) {
        logger.info("Attempting to create user: {}", user.getUsername());
        if (userManagementService.isUsernameExists(user.getUsername())) {
            logger.warn("Username already exists: {}", user.getUsername());
            return ResponseEntity.status(HttpStatus.CONFLICT).build();
        }
        userManagementService.checkAndInsertIdempotency(idempotencyKey, user, "create");
        logger.info("User created successfully: {}", user.getUsername());
        return ResponseEntity.status(HttpStatus.CREATED).build();
    }

    @GetMapping("/me")
    @PreAuthorize("hasRole('USER')")
    @Operation(
            summary = "获取当前用户信息",
            description = "获取当前登录用户的详细信息，USER 角色可访问。用户信息从 JWT 令牌的 Principal 中提取。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "成功返回当前用户信息"),
            @ApiResponse(responseCode = "401", description = "未认证，用户未登录"),
            @ApiResponse(responseCode = "403", description = "无权限访问，需 USER 角色"),
            @ApiResponse(responseCode = "404", description = "未找到用户信息"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<UserManagement> getCurrentUser(
            @Parameter(hidden = true) Principal principal) {
        logger.info("Entering getCurrentUser method");
        if (principal == null) {
            logger.warn("Principal is null, no authenticated user");
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }
        String username = principal.getName();
        logger.info("Fetching current user from JWT: {}", username);
        UserManagement existingUser = userManagementService.getUserByUsername(username);
        if (existingUser != null) {
            logger.info("User found: {}", username);
            return ResponseEntity.ok(existingUser);
        } else {
            logger.warn("User not found: {}", username);
            return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
        }
    }

    @PutMapping("/me")
    @Transactional
    @PreAuthorize("hasAnyRole('USER', 'ADMIN')")
    @Operation(
            summary = "更新当前用户信息",
            description = "更新当前登录用户的信息，USER 和 ADMIN 角色可访问。需要提供幂等键以防止重复提交。操作在事务中执行。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "用户信息更新成功"),
            @ApiResponse(responseCode = "400", description = "无效的输入参数或幂等键冲突"),
            @ApiResponse(responseCode = "401", description = "未认证，用户未登录"),
            @ApiResponse(responseCode = "403", description = "无权限访问，需 USER 或 ADMIN 角色"),
            @ApiResponse(responseCode = "404", description = "未找到用户信息"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<Void> updateCurrentUser(
            @RequestBody @Parameter(description = "更新后的用户信息", required = true) UserManagement updatedUser,
            @RequestParam @Parameter(description = "幂等键，用于防止重复提交", required = true) String idempotencyKey,
            @Parameter(hidden = true) Principal principal) {
        String username = principal.getName();
        logger.info("Attempting to update current user: {}", username);
        UserManagement existingUser = userManagementService.getUserByUsername(username);
        if (existingUser != null) {
            updatedUser.setUserId(existingUser.getUserId());
            userManagementService.checkAndInsertIdempotency(idempotencyKey, updatedUser, "update");
            logger.info("User updated successfully: {}", username);
            return ResponseEntity.ok().build();
        } else {
            logger.warn("User not found: {}", username);
            return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
        }
    }

    @PutMapping("/me/password")
    @Transactional
    @PreAuthorize("hasAnyRole('USER', 'ADMIN')")
    @Operation(
            summary = "更新当前用户密码",
            description = "更新当前登录用户的密码，USER 和 ADMIN 角色可访问。需要提供幂等键以防止重复提交。密码应为纯文本字符串，操作在事务中执行。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "密码更新成功"),
            @ApiResponse(responseCode = "400", description = "无效的输入参数或幂等键冲突"),
            @ApiResponse(responseCode = "401", description = "未认证，用户未登录"),
            @ApiResponse(responseCode = "403", description = "无权限访问，需 USER 或 ADMIN 角色"),
            @ApiResponse(responseCode = "404", description = "未找到用户信息"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<Void> updatePassword(
            @RequestBody @Parameter(description = "新密码（纯文本）", required = true, example = "newPassword123") String password,
            @RequestParam @Parameter(description = "幂等键，用于防止重复提交", required = true) String idempotencyKey,
            @Parameter(hidden = true) Principal principal) {
        if (principal == null) {
            logger.warn("Principal is null, no authenticated user");
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }
        String username = principal.getName();
        logger.info("Attempting to update password for user: {}", username);
        UserManagement existingUser = userManagementService.getUserByUsername(username);
        if (existingUser != null) {
            String cleanedPassword = password.replaceAll("^\"|\"$", "");
            existingUser.setPassword(cleanedPassword);
            userManagementService.checkAndInsertIdempotency(idempotencyKey, existingUser, "update");
            logger.info("Password updated successfully for user: {}", username);
            return ResponseEntity.ok().build();
        } else {
            logger.warn("User not found: {}", username);
            return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
        }
    }

    @GetMapping
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    @Operation(
            summary = "获取所有用户记录",
            description = "获取所有用户记录的列表，USER 和 ADMIN 角色均可访问。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "成功返回用户记录列表"),
            @ApiResponse(responseCode = "403", description = "无权限访问，需 USER 或 ADMIN 角色"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<List<UserManagement>> getAllUsers() {
        logger.info("Fetching all users");
        List<UserManagement> users = userManagementService.getAllUsers();
        logger.info("Total users found: {}", users.size());
        return ResponseEntity.ok(users);
    }

    @GetMapping("/{userId}")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    @Operation(
            summary = "根据ID获取用户记录",
            description = "获取指定ID的用户记录，USER 和 ADMIN 角色均可访问。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "成功返回用户记录"),
            @ApiResponse(responseCode = "403", description = "无权限访问，需 USER 或 ADMIN 角色"),
            @ApiResponse(responseCode = "404", description = "未找到用户记录"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<UserManagement> getUserById(
            @PathVariable @Parameter(description = "用户ID", required = true) int userId) {
        logger.info("Fetching user by ID: {}", userId);
        UserManagement user = userManagementService.getUserById(userId);
        if (user != null) {
            logger.info("User found: {}", userId);
            return ResponseEntity.ok(user);
        } else {
            logger.warn("User not found: {}", userId);
            return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
        }
    }

    @GetMapping("/username/{username}")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    @Operation(
            summary = "根据用户名获取用户记录",
            description = "获取指定用户名的用户记录，USER 和 ADMIN 角色均可访问。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "成功返回用户记录"),
            @ApiResponse(responseCode = "403", description = "无权限访问，需 USER 或 ADMIN 角色"),
            @ApiResponse(responseCode = "404", description = "未找到用户记录"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<UserManagement> getUserByUsername(
            @PathVariable @Parameter(description = "用户名", required = true) String username) {
        logger.info("Fetching user by username: {}", username);
        UserManagement user = userManagementService.getUserByUsername(username);
        if (user != null) {
            logger.info("User found: {}", username);
            return ResponseEntity.ok(user);
        } else {
            logger.warn("User not found: {}", username);
            return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
        }
    }

    @GetMapping("/role/{roleName}")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    @Operation(
            summary = "根据角色获取用户记录",
            description = "获取指定角色的用户记录列表，USER 和 ADMIN 角色均可访问。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "成功返回用户记录列表"),
            @ApiResponse(responseCode = "403", description = "无权限访问，需 USER 或 ADMIN 角色"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<List<UserManagement>> getUsersByRole(
            @PathVariable @Parameter(description = "角色名称（如 ADMIN、USER）", required = true) String roleName) {
        logger.info("Fetching users by role: {}", roleName);
        List<UserManagement> users = userManagementService.getUsersByRole(roleName);
        logger.info("Total users of role {}: {}", roleName, users.size());
        return ResponseEntity.ok(users);
    }

    @GetMapping("/status/{status}")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    @Operation(
            summary = "根据状态获取用户记录",
            description = "获取指定状态的用户记录列表，USER 和 ADMIN 角色均可访问。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "成功返回用户记录列表"),
            @ApiResponse(responseCode = "403", description = "无权限访问，需 USER 或 ADMIN 角色"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<List<UserManagement>> getUsersByStatus(
            @PathVariable @Parameter(description = "用户状态（如 ACTIVE、INACTIVE）", required = true) String status) {
        logger.info("Fetching users by status: {}", status);
        List<UserManagement> users = userManagementService.getUsersByStatus(status);
        logger.info("Total users with status {}: {}", status, users.size());
        return ResponseEntity.ok(users);
    }

    @PutMapping("/{userId}")
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(
            summary = "更新指定用户记录",
            description = "管理员更新指定ID的用户记录，仅限 ADMIN 角色。需要提供幂等键以防止重复提交。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "用户记录更新成功"),
            @ApiResponse(responseCode = "400", description = "无效的输入参数或幂等键冲突"),
            @ApiResponse(responseCode = "403", description = "无权限访问，仅限 ADMIN 角色"),
            @ApiResponse(responseCode = "404", description = "未找到用户记录"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<Void> updateUser(
            @PathVariable @Parameter(description = "用户ID", required = true) int userId,
            @RequestBody @Parameter(description = "更新后的用户信息", required = true) UserManagement updatedUser,
            @RequestParam @Parameter(description = "幂等键，用于防止重复提交", required = true) String idempotencyKey) {
        logger.info("Attempting to update user: {}", userId);
        UserManagement existingUser = userManagementService.getUserById(userId);
        if (existingUser != null) {
            updatedUser.setUserId(userId);
            userManagementService.checkAndInsertIdempotency(idempotencyKey, updatedUser, "update");
            logger.info("User updated successfully: {}", userId);
            return ResponseEntity.ok().build();
        } else {
            logger.warn("User not found: {}", userId);
            return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
        }
    }

    @DeleteMapping("/{userId}")
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(
            summary = "根据ID删除用户记录",
            description = "管理员删除指定ID的用户记录，仅限 ADMIN 角色。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "204", description = "用户记录删除成功"),
            @ApiResponse(responseCode = "403", description = "无权限访问，仅限 ADMIN 角色"),
            @ApiResponse(responseCode = "404", description = "未找到用户记录"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<Void> deleteUser(
            @PathVariable @Parameter(description = "用户ID", required = true) int userId) {
        logger.info("Attempting to delete user: {}", userId);
        try {
            UserManagement userToDelete = userManagementService.getUserById(userId);
            if (userToDelete != null) {
                userManagementService.deleteUser(userId);
                logger.info("User deleted successfully: {}", userId);
            } else {
                logger.warn("User not found: {}", userId);
                return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
            }
        } catch (Exception e) {
            logger.error("An error occurred while processing request for user {}", userId, e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
        return ResponseEntity.noContent().build();
    }

    @DeleteMapping("/username/{username}")
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(
            summary = "根据用户名删除用户记录",
            description = "管理员删除指定用户名的用户记录，仅限 ADMIN 角色。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "204", description = "用户记录删除成功"),
            @ApiResponse(responseCode = "403", description = "无权限访问，仅限 ADMIN 角色"),
            @ApiResponse(responseCode = "404", description = "未找到用户记录"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<Void> deleteUserByUsername(
            @PathVariable @Parameter(description = "用户名", required = true) String username) {
        logger.info("Attempting to delete user by username: {}", username);
        try {
            UserManagement userToDelete = userManagementService.getUserByUsername(username);
            if (userToDelete != null) {
                userManagementService.deleteUserByUsername(username);
                logger.info("User deleted successfully: {}", username);
            } else {
                logger.warn("User not found: {}", username);
                return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
            }
        } catch (Exception e) {
            logger.error("An error occurred while processing request for user {}", username, e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/autocomplete/usernames/me")
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(
            summary = "获取用户名自动补全建议",
            description = "根据前缀获取用户名自动补全建议，仅限 ADMIN 角色。返回的用户名列表已进行 URL 解码。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "成功返回用户名建议列表"),
            @ApiResponse(responseCode = "204", description = "未找到匹配的用户名建议"),
            @ApiResponse(responseCode = "403", description = "无权限访问，仅限 ADMIN 角色"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<List<String>> getUsernameAutocompleteSuggestionsGlobally(
            @RequestParam @Parameter(description = "用户名前缀", required = true) String prefix) {
        String decodedPrefix = URLDecoder.decode(prefix, StandardCharsets.UTF_8);
        logger.info("Fetching username suggestions for prefix: {}, decoded: {}", prefix, decodedPrefix);

        List<String> suggestions = userManagementService.getUsernamesByPrefixGlobally(decodedPrefix);
        if (suggestions == null) {
            suggestions = Collections.emptyList();
        }

        if (suggestions.isEmpty()) {
            logger.info("No username suggestions found for prefix: {}", decodedPrefix);
        } else {
            logger.info("Found {} username suggestions for prefix: {}", suggestions.size(), decodedPrefix);
        }

        return ResponseEntity.ok(suggestions);
    }

    @GetMapping("/autocomplete/statuses/me")
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(
            summary = "获取状态自动补全建议",
            description = "根据前缀获取用户状态自动补全建议，仅限 ADMIN 角色。返回的状态列表已进行 URL 解码。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "成功返回状态建议列表"),
            @ApiResponse(responseCode = "204", description = "未找到匹配的状态建议"),
            @ApiResponse(responseCode = "403", description = "无权限访问，仅限 ADMIN 角色"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<List<String>> getStatusAutocompleteSuggestionsGlobally(
            @RequestParam @Parameter(description = "状态前缀（如 ACTIVE、INACTIVE）", required = true) String prefix) {
        String decodedPrefix = URLDecoder.decode(prefix, StandardCharsets.UTF_8);
        logger.info("Fetching status suggestions for prefix: {}, decoded: {}", prefix, decodedPrefix);

        List<String> suggestions = userManagementService.getStatusesByPrefixGlobally(decodedPrefix);
        if (suggestions == null) {
            suggestions = Collections.emptyList();
        }

        if (suggestions.isEmpty()) {
            logger.info("No status suggestions found for prefix: {}", decodedPrefix);
        } else {
            logger.info("Found {} status suggestions for prefix: {}", suggestions.size(), decodedPrefix);
        }

        return ResponseEntity.ok(suggestions);
    }

    @GetMapping("/autocomplete/phone-numbers/me")
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(
            summary = "获取电话号码自动补全建议",
            description = "根据前缀获取电话号码自动补全建议，仅限 ADMIN 角色。返回的电话号码列表已进行 URL 解码。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "成功返回电话号码建议列表"),
            @ApiResponse(responseCode = "204", description = "未找到匹配的电话号码建议"),
            @ApiResponse(responseCode = "403", description = "无权限访问，仅限 ADMIN 角色"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<List<String>> getPhoneNumberAutocompleteSuggestionsGlobally(
            @RequestParam @Parameter(description = "电话号码前缀", required = true) String prefix) {
        String decodedPrefix = URLDecoder.decode(prefix, StandardCharsets.UTF_8);
        logger.info("Fetching phone number suggestions for prefix: {}, decoded: {}", prefix, decodedPrefix);

        List<String> suggestions = userManagementService.getPhoneNumbersByPrefixGlobally(decodedPrefix);
        if (suggestions == null) {
            suggestions = Collections.emptyList();
        }

        if (suggestions.isEmpty()) {
            logger.info("No phone number suggestions found for prefix: {}", decodedPrefix);
        } else {
            logger.info("Found {} phone number suggestions for prefix: {}", suggestions.size(), decodedPrefix);
        }

        return ResponseEntity.ok(suggestions);
    }
}