package com.tutict.finalassignmentbackend.controller;

import com.tutict.finalassignmentbackend.entity.LoginLog;
import com.tutict.finalassignmentbackend.service.LoginLogService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;
import org.springframework.security.access.prepost.PreAuthorize;

import java.net.URLDecoder;
import java.nio.charset.StandardCharsets;
import java.util.Collections;
import java.util.Date;
import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;

@RestController
@RequestMapping("/api/loginLogs")
@SecurityRequirement(name = "bearerAuth")
@Tag(name = "Login Log", description = "APIs for managing login log records")
public class LoginLogController {

    private static final Logger log = Logger.getLogger(LoginLogController.class.getName());

    private final LoginLogService loginLogService;

    public LoginLogController(LoginLogService loginLogService) {
        this.loginLogService = loginLogService;
    }

    @PostMapping
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    @Operation(
            summary = "创建登录日志",
            description = "创建新的登录日志记录，USER 和 ADMIN 角色均可访问。需要提供幂等键以防止重复提交。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "201", description = "登录日志创建成功"),
            @ApiResponse(responseCode = "400", description = "无效的输入参数或幂等键冲突"),
            @ApiResponse(responseCode = "403", description = "无权限访问，需 USER 或 ADMIN 角色"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<Void> createLoginLog(
            @RequestBody @Parameter(description = "登录日志的详细信息", required = true) LoginLog loginLog,
            @RequestParam @Parameter(description = "幂等键，用于防止重复提交", required = true) String idempotencyKey) {
        loginLogService.checkAndInsertIdempotency(idempotencyKey, loginLog, "create");
        return ResponseEntity.status(HttpStatus.CREATED).build();
    }

    @GetMapping("/{logId}")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    @Operation(
            summary = "根据ID获取登录日志",
            description = "获取指定ID的登录日志，USER 和 ADMIN 角色均可访问。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "成功返回登录日志"),
            @ApiResponse(responseCode = "403", description = "无权限访问，需 USER 或 ADMIN 角色"),
            @ApiResponse(responseCode = "404", description = "未找到登录日志"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<LoginLog> getLoginLog(
            @PathVariable @Parameter(description = "登录日志ID", required = true) int logId) {
        LoginLog loginLog = loginLogService.getLoginLog(logId);
        if (loginLog != null) {
            return ResponseEntity.ok(loginLog);
        } else {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
        }
    }

    @GetMapping
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    @Operation(
            summary = "获取所有登录日志",
            description = "获取所有登录日志的列表，USER 和 ADMIN 角色均可访问。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "成功返回登录日志列表"),
            @ApiResponse(responseCode = "403", description = "无权限访问，需 USER 或 ADMIN 角色"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<List<LoginLog>> getAllLoginLogs() {
        List<LoginLog> loginLogs = loginLogService.getAllLoginLogs();
        return ResponseEntity.ok(loginLogs);
    }

    @PutMapping("/{logId}")
    @Transactional
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(
            summary = "更新登录日志",
            description = "管理员更新指定ID的登录日志，需要提供幂等键以防止重复提交。操作在事务中执行。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "登录日志更新成功"),
            @ApiResponse(responseCode = "400", description = "无效的输入参数或幂等键冲突"),
            @ApiResponse(responseCode = "403", description = "无权限访问，仅限 ADMIN 角色"),
            @ApiResponse(responseCode = "404", description = "未找到登录日志"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<LoginLog> updateLoginLog(
            @PathVariable @Parameter(description = "登录日志ID", required = true) int logId,
            @RequestBody @Parameter(description = "更新后的登录日志信息", required = true) LoginLog updatedLoginLog,
            @RequestParam @Parameter(description = "幂等键，用于防止重复提交", required = true) String idempotencyKey) {
        LoginLog existingLoginLog = loginLogService.getLoginLog(logId);
        if (existingLoginLog != null) {
            updatedLoginLog.setLogId(logId);
            loginLogService.checkAndInsertIdempotency(idempotencyKey, updatedLoginLog, "update");
            return ResponseEntity.ok(updatedLoginLog);
        } else {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
        }
    }

    @DeleteMapping("/{logId}")
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(
            summary = "删除登录日志",
            description = "管理员删除指定ID的登录日志，仅限 ADMIN 角色。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "204", description = "登录日志删除成功"),
            @ApiResponse(responseCode = "403", description = "无权限访问，仅限 ADMIN 角色"),
            @ApiResponse(responseCode = "404", description = "未找到登录日志"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<Void> deleteLoginLog(
            @PathVariable @Parameter(description = "登录日志ID", required = true) int logId) {
        loginLogService.deleteLoginLog(logId);
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/timeRange")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    @Operation(
            summary = "根据时间范围获取登录日志",
            description = "获取指定时间范围内的登录日志列表，USER 和 ADMIN 角色均可访问。时间格式为 yyyy-MM-dd。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "成功返回登录日志列表"),
            @ApiResponse(responseCode = "400", description = "无效的时间范围参数"),
            @ApiResponse(responseCode = "403", description = "无权限访问，需 USER 或 ADMIN 角色"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<List<LoginLog>> getLoginLogsByTimeRange(
            @RequestParam(defaultValue = "1970-01-01") @Parameter(description = "开始时间，格式：yyyy-MM-dd", example = "1970-01-01") Date startTime,
            @RequestParam(defaultValue = "2100-01-01") @Parameter(description = "结束时间，格式：yyyy-MM-dd", example = "2100-01-01") Date endTime) {
        List<LoginLog> loginLogs = loginLogService.getLoginLogsByTimeRange(startTime, endTime);
        return ResponseEntity.ok(loginLogs);
    }

    @GetMapping("/username/{username}")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    @Operation(
            summary = "根据用户名获取登录日志",
            description = "获取指定用户名的登录日志列表，USER 和 ADMIN 角色均可访问。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "成功返回登录日志列表"),
            @ApiResponse(responseCode = "403", description = "无权限访问，需 USER 或 ADMIN 角色"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<List<LoginLog>> getLoginLogsByUsername(
            @PathVariable @Parameter(description = "用户名", required = true) String username) {
        List<LoginLog> loginLogs = loginLogService.getLoginLogsByUsername(username);
        return ResponseEntity.ok(loginLogs);
    }

    @GetMapping("/loginResult/{loginResult}")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    @Operation(
            summary = "根据登录结果获取登录日志",
            description = "获取指定登录结果的登录日志列表，USER 和 ADMIN 角色均可访问。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "成功返回登录日志列表"),
            @ApiResponse(responseCode = "403", description = "无权限访问，需 USER 或 ADMIN 角色"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<List<LoginLog>> getLoginLogsByLoginResult(
            @PathVariable @Parameter(description = "登录结果（如 SUCCESS 或 FAILURE）", required = true) String loginResult) {
        List<LoginLog> loginLogs = loginLogService.getLoginLogsByLoginResult(loginResult);
        return ResponseEntity.ok(loginLogs);
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
        log.log(Level.INFO, "Fetching username suggestions for prefix: {0}, decoded: {1}",
                new Object[]{prefix, decodedPrefix});

        List<String> suggestions = loginLogService.getUsernamesByPrefixGlobally(decodedPrefix);
        if (suggestions == null) {
            suggestions = Collections.emptyList();
        }

        if (suggestions.isEmpty()) {
            log.log(Level.INFO, "No username suggestions found for prefix: {0}", new Object[]{decodedPrefix});
        } else {
            log.log(Level.INFO, "Found {0} username suggestions for prefix: {1}",
                    new Object[]{suggestions.size(), decodedPrefix});
        }

        return ResponseEntity.ok(suggestions);
    }

    @GetMapping("/autocomplete/login-results/me")
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(
            summary = "获取登录结果自动补全建议",
            description = "根据前缀获取登录结果自动补全建议，仅限 ADMIN 角色。返回的登录结果列表已进行 URL 解码。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "成功返回登录结果建议列表"),
            @ApiResponse(responseCode = "204", description = "未找到匹配的登录结果建议"),
            @ApiResponse(responseCode = "403", description = "无权限访问，仅限 ADMIN 角色"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<List<String>> getLoginResultAutocompleteSuggestionsGlobally(
            @RequestParam @Parameter(description = "登录结果前缀", required = true) String prefix) {
        String decodedPrefix = URLDecoder.decode(prefix, StandardCharsets.UTF_8);
        log.log(Level.INFO, "Fetching login result suggestions for prefix: {0}, decoded: {1}",
                new Object[]{prefix, decodedPrefix});

        List<String> suggestions = loginLogService.getLoginResultsByPrefixGlobally(decodedPrefix);
        if (suggestions == null) {
            suggestions = Collections.emptyList();
        }

        if (suggestions.isEmpty()) {
            log.log(Level.INFO, "No login result suggestions found for prefix: {0}", new Object[]{decodedPrefix});
        } else {
            log.log(Level.INFO, "Found {0} login result suggestions for prefix: {1}",
                    new Object[]{suggestions.size(), decodedPrefix});
        }

        return ResponseEntity.ok(suggestions);
    }
}