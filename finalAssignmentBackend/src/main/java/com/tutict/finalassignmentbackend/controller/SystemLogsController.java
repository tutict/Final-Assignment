package com.tutict.finalassignmentbackend.controller;

import com.tutict.finalassignmentbackend.entity.SystemLogs;
import com.tutict.finalassignmentbackend.service.SystemLogsService;
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
@RequestMapping("/api/systemLogs")
@SecurityRequirement(name = "bearerAuth")
@Tag(name = "System Logs", description = "APIs for managing system log records")
public class SystemLogsController {

    private static final Logger log = Logger.getLogger(SystemLogsController.class.getName());
    private final SystemLogsService systemLogsService;

    public SystemLogsController(SystemLogsService systemLogsService) {
        this.systemLogsService = systemLogsService;
    }

    @PostMapping
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    @Operation(
            summary = "创建系统日志记录",
            description = "创建新的系统日志记录，USER 和 ADMIN 角色均可访问。需要提供幂等键以防止重复提交。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "201", description = "系统日志记录创建成功"),
            @ApiResponse(responseCode = "400", description = "无效的输入参数或幂等键冲突"),
            @ApiResponse(responseCode = "403", description = "无权限访问，需 USER 或 ADMIN 角色"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<Void> createSystemLog(
            @RequestBody @Parameter(description = "系统日志记录的详细信息", required = true) SystemLogs systemLog,
            @RequestParam @Parameter(description = "幂等键，用于防止重复提交", required = true) String idempotencyKey) {
        systemLogsService.checkAndInsertIdempotency(idempotencyKey, systemLog, "create");
        return ResponseEntity.status(HttpStatus.CREATED).build();
    }

    @GetMapping("/{logId}")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    @Operation(
            summary = "根据ID获取系统日志记录",
            description = "获取指定ID的系统日志记录，USER 和 ADMIN 角色均可访问。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "成功返回系统日志记录"),
            @ApiResponse(responseCode = "403", description = "无权限访问，需 USER 或 ADMIN 角色"),
            @ApiResponse(responseCode = "404", description = "未找到系统日志记录"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<SystemLogs> getSystemLogById(
            @PathVariable @Parameter(description = "系统日志ID", required = true) int logId) {
        SystemLogs systemLog = systemLogsService.getSystemLogById(logId);
        if (systemLog != null) {
            return ResponseEntity.ok(systemLog);
        } else {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
        }
    }

    @GetMapping
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    @Operation(
            summary = "获取所有系统日志记录",
            description = "获取所有系统日志记录的列表，USER 和 ADMIN 角色均可访问。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "成功返回系统日志记录列表"),
            @ApiResponse(responseCode = "403", description = "无权限访问，需 USER 或 ADMIN 角色"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<List<SystemLogs>> getAllSystemLogs() {
        List<SystemLogs> systemLogs = systemLogsService.getAllSystemLogs();
        return ResponseEntity.ok(systemLogs);
    }

    @GetMapping("/type/{logType}")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    @Operation(
            summary = "根据日志类型获取系统日志记录",
            description = "获取指定日志类型的系统日志记录列表，USER 和 ADMIN 角色均可访问。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "成功返回系统日志记录列表"),
            @ApiResponse(responseCode = "403", description = "无权限访问，需 USER 或 ADMIN 角色"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<List<SystemLogs>> getSystemLogsByType(
            @PathVariable @Parameter(description = "日志类型（如 INFO、ERROR）", required = true) String logType) {
        List<SystemLogs> systemLogs = systemLogsService.getSystemLogsByType(logType);
        return ResponseEntity.ok(systemLogs);
    }

    @GetMapping("/timeRange")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    @Operation(
            summary = "根据时间范围获取系统日志记录",
            description = "获取指定时间范围内的系统日志记录列表，USER 和 ADMIN 角色均可访问。时间格式为 yyyy-MM-dd。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "成功返回系统日志记录列表"),
            @ApiResponse(responseCode = "400", description = "无效的时间范围参数"),
            @ApiResponse(responseCode = "403", description = "无权限访问，需 USER 或 ADMIN 角色"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<List<SystemLogs>> getSystemLogsByTimeRange(
            @RequestParam @Parameter(description = "开始时间，格式：yyyy-MM-dd", required = true, example = "2023-01-01") Date startTime,
            @RequestParam @Parameter(description = "结束时间，格式：yyyy-MM-dd", required = true, example = "2023-12-31") Date endTime) {
        List<SystemLogs> systemLogs = systemLogsService.getSystemLogsByTimeRange(startTime, endTime);
        return ResponseEntity.ok(systemLogs);
    }

    @GetMapping("/operationUser/{operationUser}")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    @Operation(
            summary = "根据操作用户获取系统日志记录",
            description = "获取指定操作用户的系统日志记录列表，USER 和 ADMIN 角色均可访问。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "成功返回系统日志记录列表"),
            @ApiResponse(responseCode = "403", description = "无权限访问，需 USER 或 ADMIN 角色"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<List<SystemLogs>> getSystemLogsByOperationUser(
            @PathVariable @Parameter(description = "操作用户ID", required = true) String operationUser) {
        List<SystemLogs> systemLogs = systemLogsService.getSystemLogsByOperationUser(operationUser);
        return ResponseEntity.ok(systemLogs);
    }

    @PutMapping("/{logId}")
    @Transactional
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(
            summary = "更新系统日志记录",
            description = "管理员更新指定ID的系统日志记录，需要提供幂等键以防止重复提交。操作在事务中执行。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "系统日志记录更新成功"),
            @ApiResponse(responseCode = "400", description = "无效的输入参数或幂等键冲突"),
            @ApiResponse(responseCode = "403", description = "无权限访问，仅限 ADMIN 角色"),
            @ApiResponse(responseCode = "404", description = "未找到系统日志记录"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<SystemLogs> updateSystemLog(
            @PathVariable @Parameter(description = "系统日志ID", required = true) int logId,
            @RequestBody @Parameter(description = "更新后的系统日志记录信息", required = true) SystemLogs updatedSystemLog,
            @RequestParam @Parameter(description = "幂等键，用于防止重复提交", required = true) String idempotencyKey) {
        SystemLogs existingSystemLog = systemLogsService.getSystemLogById(logId);
        if (existingSystemLog != null) {
            updatedSystemLog.setLogId(logId);
            systemLogsService.checkAndInsertIdempotency(idempotencyKey, updatedSystemLog, "update");
            return ResponseEntity.ok(updatedSystemLog);
        } else {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
        }
    }

    @DeleteMapping("/{logId}")
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(
            summary = "删除系统日志记录",
            description = "管理员删除指定ID的系统日志记录，仅限 ADMIN 角色。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "204", description = "系统日志记录删除成功"),
            @ApiResponse(responseCode = "403", description = "无权限访问，仅限 ADMIN 角色"),
            @ApiResponse(responseCode = "404", description = "未找到系统日志记录"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<Void> deleteSystemLog(
            @PathVariable @Parameter(description = "系统日志ID", required = true) int logId) {
        systemLogsService.deleteSystemLog(logId);
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/autocomplete/log-types/me")
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(
            summary = "获取日志类型自动补全建议",
            description = "根据前缀获取日志类型自动补全建议，仅限 ADMIN 角色。返回的日志类型列表已进行 URL 解码。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "成功返回日志类型建议列表"),
            @ApiResponse(responseCode = "204", description = "未找到匹配的日志类型建议"),
            @ApiResponse(responseCode = "403", description = "无权限访问，仅限 ADMIN 角色"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<List<String>> getLogTypeAutocompleteSuggestionsGlobally(
            @RequestParam @Parameter(description = "日志类型前缀", required = true) String prefix) {
        String decodedPrefix = URLDecoder.decode(prefix, StandardCharsets.UTF_8);
        log.log(Level.INFO, "Fetching log type suggestions for prefix: {0}, decoded: {1}",
                new Object[]{prefix, decodedPrefix});

        List<String> suggestions = systemLogsService.getLogTypesByPrefixGlobally(decodedPrefix);
        if (suggestions == null) {
            suggestions = Collections.emptyList();
        }

        if (suggestions.isEmpty()) {
            log.log(Level.INFO, "No log type suggestions found for prefix: {0}", new Object[]{decodedPrefix});
        } else {
            log.log(Level.INFO, "Found {0} log type suggestions for prefix: {1}",
                    new Object[]{suggestions.size(), decodedPrefix});
        }

        return ResponseEntity.ok(suggestions);
    }

    @GetMapping("/autocomplete/operation-users/me")
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(
            summary = "获取操作用户自动补全建议",
            description = "根据前缀获取操作用户自动补全建议，仅限 ADMIN 角色。返回的操作用户列表已进行 URL 解码。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "成功返回操作用户建议列表"),
            @ApiResponse(responseCode = "204", description = "未找到匹配的操作用户建议"),
            @ApiResponse(responseCode = "403", description = "无权限访问，仅限 ADMIN 角色"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<List<String>> getOperationUserAutocompleteSuggestionsGlobally(
            @RequestParam @Parameter(description = "操作用户前缀", required = true) String prefix) {
        String decodedPrefix = URLDecoder.decode(prefix, StandardCharsets.UTF_8);
        log.log(Level.INFO, "Fetching operation user suggestions for prefix: {0}, decoded: {1}",
                new Object[]{prefix, decodedPrefix});

        List<String> suggestions = systemLogsService.getOperationUsersByPrefixGlobally(decodedPrefix);
        if (suggestions == null) {
            suggestions = Collections.emptyList();
        }

        if (suggestions.isEmpty()) {
            log.log(Level.INFO, "No operation user suggestions found for prefix: {0}", new Object[]{decodedPrefix});
        } else {
            log.log(Level.INFO, "Found {0} operation user suggestions for prefix: {1}",
                    new Object[]{suggestions.size(), decodedPrefix});
        }

        return ResponseEntity.ok(suggestions);
    }
}