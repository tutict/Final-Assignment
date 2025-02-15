package com.tutict.finalassignmentbackend.controller;

import com.tutict.finalassignmentbackend.entity.LoginLog;
import com.tutict.finalassignmentbackend.service.LoginLogService;
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
@RequestMapping("/api/loginLogs")
public class LoginLogController {

    private static final ExecutorService virtualThreadExecutor = Executors.newVirtualThreadPerTaskExecutor();

    private final LoginLogService loginLogService;

    public LoginLogController(LoginLogService loginLogService) {
        this.loginLogService = loginLogService;
    }

    // 创建新的登录日志
    @PostMapping
    @Async
    public CompletableFuture<ResponseEntity<Void>> createLoginLog(@RequestBody LoginLog loginLog, @RequestParam String idempotencyKey) {
        return CompletableFuture.supplyAsync(() -> {
            loginLogService.checkAndInsertIdempotency(idempotencyKey, loginLog, "create");
            return ResponseEntity.status(HttpStatus.CREATED).build();
        }, virtualThreadExecutor);
    }

    // 根据日志ID获取登录日志
    @GetMapping("/{logId}")
    @Async
    public CompletableFuture<ResponseEntity<LoginLog>> getLoginLog(@PathVariable int logId) {
        return CompletableFuture.supplyAsync(() -> {
            LoginLog loginLog = loginLogService.getLoginLog(logId);
            if (loginLog != null) {
                return ResponseEntity.ok(loginLog);
            } else {
                return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
            }
        }, virtualThreadExecutor);
    }

    // 获取所有登录日志
    @GetMapping
    @Async
    public CompletableFuture<ResponseEntity<List<LoginLog>>> getAllLoginLogs() {
        return CompletableFuture.supplyAsync(() -> {
            List<LoginLog> loginLogs = loginLogService.getAllLoginLogs();
            return ResponseEntity.ok(loginLogs);
        }, virtualThreadExecutor);
    }

    // 更新登录日志
    @PutMapping("/{logId}")
    @Async
    @Transactional
    public CompletableFuture<ResponseEntity<LoginLog>> updateLoginLog(@PathVariable int logId, @RequestBody LoginLog updatedLoginLog, @RequestParam String idempotencyKey) {
        return CompletableFuture.supplyAsync(() -> {
            LoginLog existingLoginLog = loginLogService.getLoginLog(logId);
            if (existingLoginLog != null) {
                updatedLoginLog.setLogId(logId);
                loginLogService.checkAndInsertIdempotency(idempotencyKey, updatedLoginLog, "update");
                return ResponseEntity.ok(updatedLoginLog);
            } else {
                return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
            }
        }, virtualThreadExecutor);
    }

    // 删除指定ID的登录日志
    @DeleteMapping("/{logId}")
    @Async
    public CompletableFuture<ResponseEntity<Void>> deleteLoginLog(@PathVariable int logId) {
        return CompletableFuture.supplyAsync(() -> {
            loginLogService.deleteLoginLog(logId);
            return ResponseEntity.noContent().build();
        }, virtualThreadExecutor);
    }

    // 根据时间范围获取登录日志
    @GetMapping("/timeRange")
    @Async
    public CompletableFuture<ResponseEntity<List<LoginLog>>> getLoginLogsByTimeRange(
            @RequestParam(defaultValue = "1970-01-01") Date startTime,
            @RequestParam(defaultValue = "2100-01-01") Date endTime) {
        return CompletableFuture.supplyAsync(() -> {
            List<LoginLog> loginLogs = loginLogService.getLoginLogsByTimeRange(startTime, endTime);
            return ResponseEntity.ok(loginLogs);
        }, virtualThreadExecutor);
    }

    // 根据用户名获取登录日志
    @GetMapping("/username/{username}")
    @Async
    public CompletableFuture<ResponseEntity<List<LoginLog>>> getLoginLogsByUsername(@PathVariable String username) {
        return CompletableFuture.supplyAsync(() -> {
            List<LoginLog> loginLogs = loginLogService.getLoginLogsByUsername(username);
            return ResponseEntity.ok(loginLogs);
        }, virtualThreadExecutor);
    }

    // 根据登录结果获取登录日志
    @GetMapping("/loginResult/{loginResult}")
    @Async
    public CompletableFuture<ResponseEntity<List<LoginLog>>> getLoginLogsByLoginResult(@PathVariable String loginResult) {
        return CompletableFuture.supplyAsync(() -> {
            List<LoginLog> loginLogs = loginLogService.getLoginLogsByLoginResult(loginResult);
            return ResponseEntity.ok(loginLogs);
        }, virtualThreadExecutor);
    }
}
