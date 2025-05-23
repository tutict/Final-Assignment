package com.tutict.finalassignmentbackend.controller;

import com.tutict.finalassignmentbackend.entity.OperationLog;
import com.tutict.finalassignmentbackend.service.OperationLogService;
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
public class OperationLogController {

    private final OperationLogService operationLogService;
    private static final Logger log = Logger.getLogger(OperationLogController.class.getName());


    public OperationLogController(OperationLogService operationLogService) {
        this.operationLogService = operationLogService;
    }

    // 创建新的操作日志 (仅 ADMIN)
    @PostMapping
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public ResponseEntity<Void> createOperationLog(@RequestBody OperationLog operationLog, @RequestParam String idempotencyKey) {
        operationLogService.checkAndInsertIdempotency(idempotencyKey, operationLog, "create");
        return ResponseEntity.status(HttpStatus.CREATED).build();
    }

    // 根据日志ID获取操作日志 (USER 和 ADMIN)
    @GetMapping("/{logId}")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public ResponseEntity<OperationLog> getOperationLog(@PathVariable int logId) {
        OperationLog operationLog = operationLogService.getOperationLog(logId);
        if (operationLog != null) {
            return ResponseEntity.ok(operationLog);
        } else {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
        }
    }

    // 获取所有操作日志 (USER 和 ADMIN)
    @GetMapping
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public ResponseEntity<List<OperationLog>> getAllOperationLogs() {
        List<OperationLog> operationLogs = operationLogService.getAllOperationLogs();
        return ResponseEntity.ok(operationLogs);
    }

    // 更新指定操作日志的信息 (仅 ADMIN)
    @PutMapping("/{logId}")
    @Transactional
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<OperationLog> updateOperationLog(@PathVariable int logId, @RequestBody OperationLog updatedOperationLog, @RequestParam String idempotencyKey) {
        OperationLog existingOperationLog = operationLogService.getOperationLog(logId);
        if (existingOperationLog != null) {
            updatedOperationLog.setLogId(logId);
            operationLogService.checkAndInsertIdempotency(idempotencyKey, updatedOperationLog, "update");
            return ResponseEntity.ok(updatedOperationLog);
        } else {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
        }
    }

    // 删除指定操作日志的信息 (仅 ADMIN)
    @DeleteMapping("/{logId}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Void> deleteOperationLog(@PathVariable int logId) {
        operationLogService.deleteOperationLog(logId);
        return ResponseEntity.noContent().build();
    }

    // 根据时间范围获取操作日志 (USER 和 ADMIN)
    @GetMapping("/timeRange")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public ResponseEntity<List<OperationLog>> getOperationLogsByTimeRange(
            @RequestParam(defaultValue = "1970-01-01") Date startTime,
            @RequestParam(defaultValue = "2100-01-01") Date endTime) {
        List<OperationLog> operationLogs = operationLogService.getOperationLogsByTimeRange(startTime, endTime);
        return ResponseEntity.ok(operationLogs);
    }

    // 根据用户ID获取操作日志 (USER 和 ADMIN)
    @GetMapping("/userId/{userId}")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public ResponseEntity<List<OperationLog>> getOperationLogsByUserId(@PathVariable String userId) {
        List<OperationLog> operationLogs = operationLogService.getOperationLogsByUserId(userId);
        return ResponseEntity.ok(operationLogs);
    }

    // 根据操作结果获取操作日志 (USER 和 ADMIN)
    @GetMapping("/result/{result}")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public ResponseEntity<List<OperationLog>> getOperationLogsByResult(@PathVariable String result) {
        List<OperationLog> operationLogs = operationLogService.getOperationLogsByResult(result);
        return ResponseEntity.ok(operationLogs);
    }

    @GetMapping("/autocomplete/user-ids/me")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<List<String>> getUserIdAutocompleteSuggestionsGlobally(
            @RequestParam String prefix) {
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
    public ResponseEntity<List<String>> getOperationResultAutocompleteSuggestionsGlobally(
            @RequestParam String prefix) {
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
