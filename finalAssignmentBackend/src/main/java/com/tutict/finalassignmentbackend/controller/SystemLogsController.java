package com.tutict.finalassignmentbackend.controller;

import com.tutict.finalassignmentbackend.entity.SystemLogs;
import com.tutict.finalassignmentbackend.service.SystemLogsService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.scheduling.annotation.Async;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.Date;
import java.util.List;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

@RestController
@RequestMapping("/api/systemLogs")
public class SystemLogsController {

    private static final ExecutorService virtualThreadExecutor = Executors.newVirtualThreadPerTaskExecutor();

    private final SystemLogsService systemLogsService;

    public SystemLogsController(SystemLogsService systemLogsService) {
        this.systemLogsService = systemLogsService;
    }

    // 创建新的系统日志记录
    @PostMapping
    @Async
    public CompletableFuture<ResponseEntity<Void>> createSystemLog(@RequestBody SystemLogs systemLog, @RequestParam String idempotencyKey) {
        return CompletableFuture.supplyAsync(() -> {
            systemLogsService.checkAndInsertIdempotency(idempotencyKey, systemLog, "create");
            return ResponseEntity.status(HttpStatus.CREATED).build();
        }, virtualThreadExecutor);
    }

    // 根据日志ID获取系统日志信息
    @GetMapping("/{logId}")
    @Async
    public CompletableFuture<ResponseEntity<SystemLogs>> getSystemLogById(@PathVariable int logId) {
        return CompletableFuture.supplyAsync(() -> {
            SystemLogs systemLog = systemLogsService.getSystemLogById(logId);
            if (systemLog != null) {
                return ResponseEntity.ok(systemLog);
            } else {
                return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
            }
        }, virtualThreadExecutor);
    }

    // 获取所有系统日志
    @GetMapping
    @Async
    public CompletableFuture<ResponseEntity<List<SystemLogs>>> getAllSystemLogs() {
        return CompletableFuture.supplyAsync(() -> {
            List<SystemLogs> systemLogs = systemLogsService.getAllSystemLogs();
            return ResponseEntity.ok(systemLogs);
        }, virtualThreadExecutor);
    }

    // 根据日志类型获取系统日志
    @GetMapping("/type/{logType}")
    @Async
    public CompletableFuture<ResponseEntity<List<SystemLogs>>> getSystemLogsByType(@PathVariable String logType) {
        return CompletableFuture.supplyAsync(() -> {
            List<SystemLogs> systemLogs = systemLogsService.getSystemLogsByType(logType);
            return ResponseEntity.ok(systemLogs);
        }, virtualThreadExecutor);
    }

    // 根据时间范围获取系统日志
    @GetMapping("/timeRange")
    @Async
    public CompletableFuture<ResponseEntity<List<SystemLogs>>> getSystemLogsByTimeRange(
            @RequestParam Date startTime,
            @RequestParam Date endTime) {
        return CompletableFuture.supplyAsync(() -> {
            List<SystemLogs> systemLogs = systemLogsService.getSystemLogsByTimeRange(startTime, endTime);
            return ResponseEntity.ok(systemLogs);
        }, virtualThreadExecutor);
    }

    // 根据操作用户获取系统日志
    @GetMapping("/operationUser/{operationUser}")
    @Async
    public CompletableFuture<ResponseEntity<List<SystemLogs>>> getSystemLogsByOperationUser(@PathVariable String operationUser) {
        return CompletableFuture.supplyAsync(() -> {
            List<SystemLogs> systemLogs = systemLogsService.getSystemLogsByOperationUser(operationUser);
            return ResponseEntity.ok(systemLogs);
        }, virtualThreadExecutor);
    }

    // 更新指定系统日志信息
    @PutMapping("/{logId}")
    @Async
    @Transactional
    public CompletableFuture<ResponseEntity<SystemLogs>> updateSystemLog(@PathVariable int logId, @RequestBody SystemLogs updatedSystemLog, @RequestParam String idempotencyKey) {
        return CompletableFuture.supplyAsync(() -> {
            SystemLogs existingSystemLog = systemLogsService.getSystemLogById(logId);
            if (existingSystemLog != null) {
                updatedSystemLog.setLogId(logId);
                systemLogsService.checkAndInsertIdempotency(idempotencyKey, updatedSystemLog, "update");
                return ResponseEntity.ok(updatedSystemLog);
            } else {
                return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
            }
        }, virtualThreadExecutor);
    }

    // 删除指定系统日志记录
    @DeleteMapping("/{logId}")
    @Async
    public CompletableFuture<ResponseEntity<Void>> deleteSystemLog(@PathVariable int logId) {
        return CompletableFuture.supplyAsync(() -> {
            systemLogsService.deleteSystemLog(logId);
            return ResponseEntity.noContent().build();
        }, virtualThreadExecutor);
    }
}
