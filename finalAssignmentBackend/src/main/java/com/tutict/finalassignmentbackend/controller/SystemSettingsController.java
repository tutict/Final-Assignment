package com.tutict.finalassignmentbackend.controller;

import com.tutict.finalassignmentbackend.entity.SystemSettings;
import com.tutict.finalassignmentbackend.service.SystemSettingsService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;
import org.springframework.security.access.prepost.PreAuthorize;

@RestController
@RequestMapping("/api/systemSettings")
public class SystemSettingsController {

    private final SystemSettingsService systemSettingsService;

    public SystemSettingsController(SystemSettingsService systemSettingsService) {
        this.systemSettingsService = systemSettingsService;
    }

    // 获取系统设置 (USER 和 ADMIN)
    @GetMapping
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public ResponseEntity<SystemSettings> getSystemSettings() {
        SystemSettings systemSettings = systemSettingsService.getSystemSettings();
        if (systemSettings != null) {
            return ResponseEntity.ok(systemSettings);
        } else {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
        }
    }

    // 更新系统设置 (仅 ADMIN)
    @PutMapping
    @Transactional
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<SystemSettings> updateSystemSettings(@RequestBody SystemSettings systemSettings, @RequestParam String idempotencyKey) {
        systemSettingsService.checkAndInsertIdempotency(idempotencyKey, systemSettings);
        return ResponseEntity.ok(systemSettings);
    }

    // 获取系统名称 (USER 和 ADMIN)
    @GetMapping("/systemName")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public ResponseEntity<String> getSystemName() {
        String systemName = systemSettingsService.getSystemName();
        if (systemName != null) {
            return ResponseEntity.ok(systemName);
        } else {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
        }
    }

    // 获取系统版本 (USER 和 ADMIN)
    @GetMapping("/systemVersion")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public ResponseEntity<String> getSystemVersion() {
        String systemVersion = systemSettingsService.getSystemVersion();
        if (systemVersion != null) {
            return ResponseEntity.ok(systemVersion);
        } else {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
        }
    }

    // 获取系统描述 (USER 和 ADMIN)
    @GetMapping("/systemDescription")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public ResponseEntity<String> getSystemDescription() {
        String systemDescription = systemSettingsService.getSystemDescription();
        if (systemDescription != null) {
            return ResponseEntity.ok(systemDescription);
        } else {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
        }
    }

    // 获取版权信息 (USER 和 ADMIN)
    @GetMapping("/copyrightInfo")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public ResponseEntity<String> getCopyrightInfo() {
        String copyrightInfo = systemSettingsService.getCopyrightInfo();
        if (copyrightInfo != null) {
            return ResponseEntity.ok(copyrightInfo);
        } else {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
        }
    }

    // 获取存储路径 (USER 和 ADMIN)
    @GetMapping("/storagePath")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public ResponseEntity<String> getStoragePath() {
        String storagePath = systemSettingsService.getStoragePath();
        if (storagePath != null) {
            return ResponseEntity.ok(storagePath);
        } else {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
        }
    }

    // 获取登录超时时间 (USER 和 ADMIN)
    @GetMapping("/loginTimeout")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public ResponseEntity<Integer> getLoginTimeout() {
        int loginTimeout = systemSettingsService.getLoginTimeout();
        return ResponseEntity.ok(loginTimeout);
    }

    // 获取会话超时时间 (USER 和 ADMIN)
    @GetMapping("/sessionTimeout")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public ResponseEntity<Integer> getSessionTimeout() {
        int sessionTimeout = systemSettingsService.getSessionTimeout();
        return ResponseEntity.ok(sessionTimeout);
    }

    // 获取日期格式 (USER 和 ADMIN)
    @GetMapping("/dateFormat")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public ResponseEntity<String> getDateFormat() {
        String dateFormat = systemSettingsService.getDateFormat();
        if (dateFormat != null) {
            return ResponseEntity.ok(dateFormat);
        } else {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
        }
    }

    // 获取分页大小 (USER 和 ADMIN)
    @GetMapping("/pageSize")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public ResponseEntity<Integer> getPageSize() {
        int pageSize = systemSettingsService.getPageSize();
        return ResponseEntity.ok(pageSize);
    }

    // 获取SMTP服务器 (USER 和 ADMIN)
    @GetMapping("/smtpServer")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public ResponseEntity<String> getSmtpServer() {
        String smtpServer = systemSettingsService.getSmtpServer();
        if (smtpServer != null) {
            return ResponseEntity.ok(smtpServer);
        } else {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
        }
    }

    // 获取邮件账户 (USER 和 ADMIN)
    @GetMapping("/emailAccount")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public ResponseEntity<String> getEmailAccount() {
        String emailAccount = systemSettingsService.getEmailAccount();
        if (emailAccount != null) {
            return ResponseEntity.ok(emailAccount);
        } else {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
        }
    }

    // 获取邮件密码 (USER 和 ADMIN)
    @GetMapping("/emailPassword")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public ResponseEntity<String> getEmailPassword() {
        String emailPassword = systemSettingsService.getEmailPassword();
        if (emailPassword != null) {
            return ResponseEntity.ok(emailPassword);
        } else {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
        }
    }
}