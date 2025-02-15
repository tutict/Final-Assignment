package com.tutict.finalassignmentbackend.controller;

import com.tutict.finalassignmentbackend.entity.OperationLog;
import com.tutict.finalassignmentbackend.service.OperationLogService;
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
@RequestMapping("/api/operationLogs")
public class OperationLogController {

    private static final ExecutorService virtualThreadExecutor = Executors.newVirtualThreadPerTaskExecutor();

    private final OperationLogService operationLogService;

    public OperationLogController(OperationLogService operationLogService) {
        this.operationLogService = operationLogService;
    }

    // 创建新的操作日志
    @PostMapping
    @Async
    public CompletableFuture<ResponseEntity<Void>> createOperationLog(@RequestBody OperationLog operationLog, @RequestParam String idempotencyKey) {
        return CompletableFuture.supplyAsync(() -> {
            operationLogService.checkAndInsertIdempotency(idempotencyKey, operationLog, "create");
            return ResponseEntity.status(HttpStatus.CREATED).build();
        }, virtualThreadExecutor);
    }

    // 根据日志ID获取操作日志
    @GetMapping("/{logId}")
    @Async
    public CompletableFuture<ResponseEntity<OperationLog>> getOperationLog(@PathVariable int logId) {
        return CompletableFuture.supplyAsync(() -> {
            OperationLog operationLog = operationLogService.getOperationLog(logId);
            if (operationLog != null) {
                return ResponseEntity.ok(operationLog);
            } else {
                return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
            }
        }, virtualThreadExecutor);
    }

    // 获取所有操作日志
    @GetMapping
    @Async
    public CompletableFuture<ResponseEntity<List<OperationLog>>> getAllOperationLogs() {
        return CompletableFuture.supplyAsync(() -> {
            List<OperationLog> operationLogs = operationLogService.getAllOperationLogs();
            return ResponseEntity.ok(operationLogs);
        }, virtualThreadExecutor);
    }

    // 更新指定操作日志的信息
    @PutMapping("/{logId}")
    @Async
    @Transactional
    public CompletableFuture<ResponseEntity<OperationLog>> updateOperationLog(@PathVariable int logId, @RequestBody OperationLog updatedOperationLog, @RequestParam String idempotencyKey) {
        return CompletableFuture.supplyAsync(() -> {
            OperationLog existingOperationLog = operationLogService.getOperationLog(logId);
            if (existingOperationLog != null) {
                updatedOperationLog.setLogId(logId);
                operationLogService.checkAndInsertIdempotency(idempotencyKey, updatedOperationLog, "update");
                return ResponseEntity.ok(updatedOperationLog);
            } else {
                return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
            }
        }, virtualThreadExecutor);
    }

    // 删除指定操作日志的信息
    @DeleteMapping("/{logId}")
    @Async
    public CompletableFuture<ResponseEntity<Void>> deleteOperationLog(@PathVariable int logId) {
        return CompletableFuture.supplyAsync(() -> {
            operationLogService.deleteOperationLog(logId);
            return ResponseEntity.noContent().build();
        }, virtualThreadExecutor);
    }

    // 根据时间范围获取操作日志
    @GetMapping("/timeRange")
    @Async
    public CompletableFuture<ResponseEntity<List<OperationLog>>> getOperationLogsByTimeRange(
            @RequestParam(defaultValue = "1970-01-01") Date startTime,
            @RequestParam(defaultValue = "2100-01-01") Date endTime) {
        return CompletableFuture.supplyAsync(() -> {
            List<OperationLog> operationLogs = operationLogService.getOperationLogsByTimeRange(startTime, endTime);
            return ResponseEntity.ok(operationLogs);
        }, virtualThreadExecutor);
    }

    // 根据用户ID获取操作日志
    @GetMapping("/userId/{userId}")
    @Async
    public CompletableFuture<ResponseEntity<List<OperationLog>>> getOperationLogsByUserId(@PathVariable String userId) {
        return CompletableFuture.supplyAsync(() -> {
            List<OperationLog> operationLogs = operationLogService.getOperationLogsByUserId(userId);
            return ResponseEntity.ok(operationLogs);
        }, virtualThreadExecutor);
    }

    // 根据操作结果获取操作日志
    @GetMapping("/result/{result}")
    @Async
    public CompletableFuture<ResponseEntity<List<OperationLog>>> getOperationLogsByResult(@PathVariable String result) {
        return CompletableFuture.supplyAsync(() -> {
            List<OperationLog> operationLogs = operationLogService.getOperationLogsByResult(result);
            return ResponseEntity.ok(operationLogs);
        }, virtualThreadExecutor);
    }
}
