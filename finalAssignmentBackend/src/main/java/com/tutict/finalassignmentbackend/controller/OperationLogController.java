package com.tutict.finalassignmentbackend.controller;

import com.tutict.finalassignmentbackend.entity.OperationLog;
import com.tutict.finalassignmentbackend.service.OperationLogService;
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
@RequestMapping("/api/operationLogs")
@SecurityRequirement(name = "bearerAuth")
@Tag(name = "Operation Log", description = "APIs for managing operation log records")
public class OperationLogController {

    private static final Logger log = Logger.getLogger(OperationLogController.class.getName());

    private final OperationLogService operationLogService;

    public OperationLogController(OperationLogService operationLogService) {
        this.operationLogService = operationLogService;
    }

    @PostMapping
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    @Operation(
            summary = "创建操作日志",
            description = "创建新的操作日志记录，USER 和 ADMIN 角色均可访问。需要提供幂等键以防止重复提交。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "201", description = "操作日志创建成功"),
            @ApiResponse(responseCode = "400", description = "无效的输入参数或幂等键冲突"),
            @ApiResponse(responseCode = "403", description = "无权限访问，需 USER 或 ADMIN 角色"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<Void> createOperationLog(
            @RequestBody @Parameter(description = "操作日志的详细信息", required = true) OperationLog operationLog,
            @RequestParam @Parameter(description = "幂等键，用于防止重复提交", required = true) String idempotencyKey) {
        operationLogService.checkAndInsertIdempotency(idempotencyKey, operationLog, "create");
        return ResponseEntity.status(HttpStatus.CREATED).build();
    }

    @GetMapping("/{logId}")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    @Operation(
            summary = "根据ID获取操作日志",
            description = "获取指定ID的操作日志，USER 和 ADMIN 角色均可访问。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "成功返回操作日志"),
            @ApiResponse(responseCode = "403", description = "无权限访问，需 USER 或 ADMIN 角色"),
            @ApiResponse(responseCode = "404", description = "未找到操作日志"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<OperationLog> getOperationLog(
            @PathVariable @Parameter(description = "操作日志ID", required = true) int logId) {
        OperationLog operationLog = operationLogService.getOperationLog(logId);
        if (operationLog != null) {
            return ResponseEntity.ok(operationLog);
        } else {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
        }
    }

    @GetMapping
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    @Operation(
            summary = "获取所有操作日志",
            description = "获取所有操作日志的列表，USER 和 ADMIN 角色均可访问。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "成功返回操作日志列表"),
            @ApiResponse(responseCode = "403", description = "无权限访问，需 USER 或 ADMIN 角色"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<List<OperationLog>> getAllOperationLogs() {
        List<OperationLog> operationLogs = operationLogService.getAllOperationLogs();
        return ResponseEntity.ok(operationLogs);
    }

    @PutMapping("/{logId}")
    @Transactional
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(
            summary = "更新操作日志",
            description = "管理员更新指定ID的操作日志，需要提供幂等键以防止重复提交。操作在事务中执行。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "操作日志更新成功"),
            @ApiResponse(responseCode = "400", description = "无效的输入参数或幂等键冲突"),
            @ApiResponse(responseCode = "403", description = "无权限访问，仅限 ADMIN 角色"),
            @ApiResponse(responseCode = "404", description = "未找到操作日志"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<OperationLog> updateOperationLog(
            @PathVariable @Parameter(description = "操作日志ID", required = true) int logId,
            @RequestBody @Parameter(description = "更新后的操作日志信息", required = true) OperationLog updatedOperationLog,
            @RequestParam @Parameter(description = "幂等键，用于防止重复提交", required = true) String idempotencyKey) {
        OperationLog existingOperationLog = operationLogService.getOperationLog(logId);
        if (existingOperationLog != null) {
            updatedOperationLog.setLogId(logId);
            operationLogService.checkAndInsertIdempotency(idempotencyKey, updatedOperationLog, "update");
            return ResponseEntity.ok(updatedOperationLog);
        } else {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
        }
    }

    @DeleteMapping("/{logId}")
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(
            summary = "删除操作日志",
            description = "管理员删除指定ID的操作日志，仅限 ADMIN 角色。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "204", description = "操作日志删除成功"),
            @ApiResponse(responseCode = "403", description = "无权限访问，仅限 ADMIN 角色"),
            @ApiResponse(responseCode = "404", description = "未找到操作日志"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<Void> deleteOperationLog(
            @PathVariable @Parameter(description = "操作日志ID", required = true) int logId) {
        operationLogService.deleteOperationLog(logId);
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/timeRange")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    @Operation(
            summary = "根据时间范围获取操作日志",
            description = "获取指定时间范围内的操作日志列表，USER 和 ADMIN 角色均可访问。时间格式为 yyyy-MM-dd。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "成功返回操作日志列表"),
            @ApiResponse(responseCode = "400", description = "无效的时间范围参数"),
            @ApiResponse(responseCode = "403", description = "无权限访问，需 USER 或 ADMIN 角色"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<List<OperationLog>> getOperationLogsByTimeRange(
            @RequestParam(defaultValue = "1970-01-01") @Parameter(description = "开始时间，格式：yyyy-MM-dd", example = "1970-01-01") Date startTime,
            @RequestParam(defaultValue = "2100-01-01") @Parameter(description = "结束时间，格式：yyyy-MM-dd", example = "2100-01-01") Date endTime) {
        List<OperationLog> operationLogs = operationLogService.getOperationLogsByTimeRange(startTime, endTime);
        return ResponseEntity.ok(operationLogs);
    }

    @GetMapping("/userId/{userId}")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    @Operation(
            summary = "根据用户ID获取操作日志",
            description = "获取指定用户ID的操作日志列表，USER 和 ADMIN 角色均可访问。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "成功返回操作日志列表"),
            @ApiResponse(responseCode = "403", description = "无权限访问，需 USER 或 ADMIN 角色"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<List<OperationLog>> getOperationLogsByUserId(
            @PathVariable @Parameter(description = "用户ID", required = true) String userId) {
        List<OperationLog> operationLogs = operationLogService.getOperationLogsByUserId(userId);
        return ResponseEntity.ok(operationLogs);
    }

    @GetMapping("/result/{result}")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    @Operation(
            summary = "根据操作结果获取操作日志",
            description = "获取指定操作结果的操作日志列表，USER 和 ADMIN 角色均可访问。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "成功返回操作日志列表"),
            @ApiResponse(responseCode = "403", description = "无权限访问，需 USER 或 ADMIN 角色"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<List<OperationLog>> getOperationLogsByResult(
            @PathVariable @Parameter(description = "操作结果（如 SUCCESS 或 FAILURE）", required = true) String result) {
        List<OperationLog> operationLogs = operationLogService.getOperationLogsByResult(result);
        return ResponseEntity.ok(operationLogs);
    }

    @GetMapping("/autocomplete/user-ids/me")
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(
            summary = "获取用户ID自动补全建议",
            description = "根据前缀获取用户ID自动补全建议，仅限 ADMIN 角色。返回的用户ID列表已进行 URL 解码。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "成功返回用户ID建议列表"),
            @ApiResponse(responseCode = "204", description = "未找到匹配的用户ID建议"),
            @ApiResponse(responseCode = "403", description = "无权限访问，仅限 ADMIN 角色"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<List<String>> getUserIdAutocompleteSuggestionsGlobally(
            @RequestParam @Parameter(description = "用户ID前缀", required = true) String prefix) {
        String decodedPrefix = URLDecoder.decode(prefix, StandardCharsets.UTF_8);
        log.log(Level.INFO, "Fetching user ID suggestions for prefix: {0}, decoded: {1}",
                new Object[]{prefix, decodedPrefix});

        List<String> suggestions = operationLogService.getUserIdsByPrefixGlobally(decodedPrefix);
        if (suggestions == null) {
            suggestions = Collections.emptyList();
        }

        if (suggestions.isEmpty()) {
            log.log(Level.INFO, "No user ID suggestions found for prefix: {0}", new Object[]{decodedPrefix});
        } else {
            log.log(Level.INFO, "Found {0} user ID suggestions for prefix: {1}",
                    new Object[]{suggestions.size(), decodedPrefix});
        }

        return ResponseEntity.ok(suggestions);
    }

    @GetMapping("/autocomplete/operation-results/me")
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(
            summary = "获取操作结果自动补全建议",
            description = "根据前缀获取操作结果自动补全建议，仅限 ADMIN 角色。返回的操作结果列表已进行 URL 解码。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "成功返回操作结果建议列表"),
            @ApiResponse(responseCode = "204", description = "未找到匹配的操作结果建议"),
            @ApiResponse(responseCode = "403", description = "无权限访问，仅限 ADMIN 角色"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<List<String>> getOperationResultAutocompleteSuggestionsGlobally(
            @RequestParam @Parameter(description = "操作结果前缀", required = true) String prefix) {
        String decodedPrefix = URLDecoder.decode(prefix, StandardCharsets.UTF_8);
        log.log(Level.INFO, "Fetching operation result suggestions for prefix: {0}, decoded: {1}",
                new Object[]{prefix, decodedPrefix});

        List<String> suggestions = operationLogService.getOperationResultsByPrefixGlobally(decodedPrefix);
        if (suggestions == null) {
            suggestions = Collections.emptyList();
        }

        if (suggestions.isEmpty()) {
            log.log(Level.INFO, "No operation result suggestions found for prefix: {0}", new Object[]{decodedPrefix});
        } else {
            log.log(Level.INFO, "Found {0} operation result suggestions for prefix: {1}",
                    new Object[]{suggestions.size(), decodedPrefix});
        }

        return ResponseEntity.ok(suggestions);
    }
}