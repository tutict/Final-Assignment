package com.tutict.finalassignmentbackend.controller;

import com.tutict.finalassignmentbackend.entity.SystemSettings;
import com.tutict.finalassignmentbackend.service.SystemSettingsService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.scheduling.annotation.Async;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

@RestController
@RequestMapping("/api/systemSettings")
public class SystemSettingsController {

    private static final ExecutorService virtualThreadExecutor = Executors.newVirtualThreadPerTaskExecutor();

    private final SystemSettingsService systemSettingsService;

    public SystemSettingsController(SystemSettingsService systemSettingsService) {
        this.systemSettingsService = systemSettingsService;
    }

    // 获取系统设置
    @GetMapping
    @Async
    public CompletableFuture<ResponseEntity<SystemSettings>> getSystemSettings() {
        return CompletableFuture.supplyAsync(() -> {
            SystemSettings systemSettings = systemSettingsService.getSystemSettings();
            if (systemSettings != null) {
                return ResponseEntity.ok(systemSettings);
            } else {
                return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
            }
        }, virtualThreadExecutor);
    }

    // 更新系统设置
    @PutMapping
    @Async
    @Transactional
    public CompletableFuture<ResponseEntity<SystemSettings>> updateSystemSettings(@RequestBody SystemSettings systemSettings, @RequestParam String idempotencyKey) {
        return CompletableFuture.supplyAsync(() -> {
            systemSettingsService.checkAndInsertIdempotency(idempotencyKey, systemSettings);
            return ResponseEntity.ok(systemSettings);
        }, virtualThreadExecutor);
    }

    // 获取系统名称
    @GetMapping("/systemName")
    @Async
    public CompletableFuture<ResponseEntity<String>> getSystemName() {
        return CompletableFuture.supplyAsync(() -> {
            String systemName = systemSettingsService.getSystemName();
            if (systemName != null) {
                return ResponseEntity.ok(systemName);
            } else {
                return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
            }
        }, virtualThreadExecutor);
    }

    // 获取系统版本
    @GetMapping("/systemVersion")
    @Async
    public CompletableFuture<ResponseEntity<String>> getSystemVersion() {
        return CompletableFuture.supplyAsync(() -> {
            String systemVersion = systemSettingsService.getSystemVersion();
            if (systemVersion != null) {
                return ResponseEntity.ok(systemVersion);
            } else {
                return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
            }
        }, virtualThreadExecutor);
    }

    // 获取系统描述
    @GetMapping("/systemDescription")
    @Async
    public CompletableFuture<ResponseEntity<String>> getSystemDescription() {
        return CompletableFuture.supplyAsync(() -> {
            String systemDescription = systemSettingsService.getSystemDescription();
            if (systemDescription != null) {
                return ResponseEntity.ok(systemDescription);
            } else {
                return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
            }
        }, virtualThreadExecutor);
    }

    // 获取版权信息
    @GetMapping("/copyrightInfo")
    @Async
    public CompletableFuture<ResponseEntity<String>> getCopyrightInfo() {
        return CompletableFuture.supplyAsync(() -> {
            String copyrightInfo = systemSettingsService.getCopyrightInfo();
            if (copyrightInfo != null) {
                return ResponseEntity.ok(copyrightInfo);
            } else {
                return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
            }
        }, virtualThreadExecutor);
    }

    // 获取存储路径
    @GetMapping("/storagePath")
    @Async
    public CompletableFuture<ResponseEntity<String>> getStoragePath() {
        return CompletableFuture.supplyAsync(() -> {
            String storagePath = systemSettingsService.getStoragePath();
            if (storagePath != null) {
                return ResponseEntity.ok(storagePath);
            } else {
                return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
            }
        }, virtualThreadExecutor);
    }

    // 获取登录超时时间
    @GetMapping("/loginTimeout")
    @Async
    public CompletableFuture<ResponseEntity<Integer>> getLoginTimeout() {
        return CompletableFuture.supplyAsync(() -> {
            int loginTimeout = systemSettingsService.getLoginTimeout();
            return ResponseEntity.ok(loginTimeout);
        }, virtualThreadExecutor);
    }

    // 获取会话超时时间
    @GetMapping("/sessionTimeout")
    @Async
    public CompletableFuture<ResponseEntity<Integer>> getSessionTimeout() {
        return CompletableFuture.supplyAsync(() -> {
            int sessionTimeout = systemSettingsService.getSessionTimeout();
            return ResponseEntity.ok(sessionTimeout);
        }, virtualThreadExecutor);
    }

    // 获取日期格式
    @GetMapping("/dateFormat")
    @Async
    public CompletableFuture<ResponseEntity<String>> getDateFormat() {
        return CompletableFuture.supplyAsync(() -> {
            String dateFormat = systemSettingsService.getDateFormat();
            if (dateFormat != null) {
                return ResponseEntity.ok(dateFormat);
            } else {
                return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
            }
        }, virtualThreadExecutor);
    }

    // 获取分页大小
    @GetMapping("/pageSize")
    @Async
    public CompletableFuture<ResponseEntity<Integer>> getPageSize() {
        return CompletableFuture.supplyAsync(() -> {
            int pageSize = systemSettingsService.getPageSize();
            return ResponseEntity.ok(pageSize);
        }, virtualThreadExecutor);
    }

    // 获取SMTP服务器
    @GetMapping("/smtpServer")
    @Async
    public CompletableFuture<ResponseEntity<String>> getSmtpServer() {
        return CompletableFuture.supplyAsync(() -> {
            String smtpServer = systemSettingsService.getSmtpServer();
            if (smtpServer != null) {
                return ResponseEntity.ok(smtpServer);
            } else {
                return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
            }
        }, virtualThreadExecutor);
    }

    // 获取邮件账户
    @GetMapping("/emailAccount")
    @Async
    public CompletableFuture<ResponseEntity<String>> getEmailAccount() {
        return CompletableFuture.supplyAsync(() -> {
            String emailAccount = systemSettingsService.getEmailAccount();
            if (emailAccount != null) {
                return ResponseEntity.ok(emailAccount);
            } else {
                return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
            }
        }, virtualThreadExecutor);
    }

    // 获取邮件密码
    @GetMapping("/emailPassword")
    @Async
    public CompletableFuture<ResponseEntity<String>> getEmailPassword() {
        return CompletableFuture.supplyAsync(() -> {
            String emailPassword = systemSettingsService.getEmailPassword();
            if (emailPassword != null) {
                return ResponseEntity.ok(emailPassword);
            } else {
                return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
            }
        }, virtualThreadExecutor);
    }
}
