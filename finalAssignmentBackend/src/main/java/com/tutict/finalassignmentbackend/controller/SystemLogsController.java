package com.tutict.finalassignmentbackend.controller;

import com.tutict.finalassignmentbackend.entity.SystemLogs;
import com.tutict.finalassignmentbackend.service.SystemLogsService;
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
public class SystemLogsController {

    private static final Logger log = Logger.getLogger(SystemLogsController.class.getName());
    private final SystemLogsService systemLogsService;

    public SystemLogsController(SystemLogsService systemLogsService) {
        this.systemLogsService = systemLogsService;
    }

    // 创建新的系统日志记录
    @PostMapping
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public ResponseEntity<Void> createSystemLog(@RequestBody SystemLogs systemLog, @RequestParam String idempotencyKey) {
        systemLogsService.checkAndInsertIdempotency(idempotencyKey, systemLog, "create");
        return ResponseEntity.status(HttpStatus.CREATED).build();
    }

    // 根据日志ID获取系统日志信息 (USER 和 ADMIN)
    @GetMapping("/{logId}")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public ResponseEntity<SystemLogs> getSystemLogById(@PathVariable int logId) {
        SystemLogs systemLog = systemLogsService.getSystemLogById(logId);
        if (systemLog != null) {
            return ResponseEntity.ok(systemLog);
        } else {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
        }
    }

    // 获取所有系统日志 (USER 和 ADMIN)
    @GetMapping
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public ResponseEntity<List<SystemLogs>> getAllSystemLogs() {
        List<SystemLogs> systemLogs = systemLogsService.getAllSystemLogs();
        return ResponseEntity.ok(systemLogs);
    }

    // 根据日志类型获取系统日志 (USER 和 ADMIN)
    @GetMapping("/type/{logType}")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public ResponseEntity<List<SystemLogs>> getSystemLogsByType(@PathVariable String logType) {
        List<SystemLogs> systemLogs = systemLogsService.getSystemLogsByType(logType);
        return ResponseEntity.ok(systemLogs);
    }

    // 根据时间范围获取系统日志 (USER 和 ADMIN)
    @GetMapping("/timeRange")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public ResponseEntity<List<SystemLogs>> getSystemLogsByTimeRange(
            @RequestParam Date startTime,
            @RequestParam Date endTime) {
        List<SystemLogs> systemLogs = systemLogsService.getSystemLogsByTimeRange(startTime, endTime);
        return ResponseEntity.ok(systemLogs);
    }

    // 根据操作用户获取系统日志 (USER 和 ADMIN)
    @GetMapping("/operationUser/{operationUser}")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public ResponseEntity<List<SystemLogs>> getSystemLogsByOperationUser(@PathVariable String operationUser) {
        List<SystemLogs> systemLogs = systemLogsService.getSystemLogsByOperationUser(operationUser);
        return ResponseEntity.ok(systemLogs);
    }

    // 更新指定系统日志信息 (仅 ADMIN)
    @PutMapping("/{logId}")
    @Transactional
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<SystemLogs> updateSystemLog(@PathVariable int logId, @RequestBody SystemLogs updatedSystemLog, @RequestParam String idempotencyKey) {
        SystemLogs existingSystemLog = systemLogsService.getSystemLogById(logId);
        if (existingSystemLog != null) {
            updatedSystemLog.setLogId(logId);
            systemLogsService.checkAndInsertIdempotency(idempotencyKey, updatedSystemLog, "update");
            return ResponseEntity.ok(updatedSystemLog);
        } else {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
        }
    }

    // 删除指定系统日志记录 (仅 ADMIN)
    @DeleteMapping("/{logId}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Void> deleteSystemLog(@PathVariable int logId) {
        systemLogsService.deleteSystemLog(logId);
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/autocomplete/log-types/me")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<List<String>> getLogTypeAutocompleteSuggestionsGlobally(
            @RequestParam String prefix) {
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
    public ResponseEntity<List<String>> getOperationUserAutocompleteSuggestionsGlobally(
            @RequestParam String prefix) {
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