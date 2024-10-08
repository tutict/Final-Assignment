package com.tutict.finalassignmentbackend.controller;

import com.tutict.finalassignmentbackend.entity.SystemSettings;
import com.tutict.finalassignmentbackend.service.SystemSettingsService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

// 控制器类，用于处理系统设置相关的HTTP请求
@RestController
@RequestMapping("/eventbus/systemSettings")
public class SystemSettingsController {

    // 系统设置服务的引用，用于操作系统设置数据
    private final SystemSettingsService systemSettingsService;

    // 构造函数，通过依赖注入初始化系统设置服务
    @Autowired
    public SystemSettingsController(SystemSettingsService systemSettingsService) {
        this.systemSettingsService = systemSettingsService;
    }

    // 获取系统设置信息
    @GetMapping
    public ResponseEntity<SystemSettings> getSystemSettings() {
        SystemSettings systemSettings = systemSettingsService.getSystemSettings();
        if (systemSettings != null) {
            return ResponseEntity.ok(systemSettings);
        } else {
            return ResponseEntity.notFound().build();
        }
    }

    // 更新系统设置信息
    @PutMapping
    public ResponseEntity<Void> updateSystemSettings(@RequestBody SystemSettings systemSettings) {
        systemSettingsService.updateSystemSettings(systemSettings);
        return ResponseEntity.ok().build();
    }

    // 获取系统名称
    @GetMapping("/systemName")
    public ResponseEntity<String> getSystemName() {
        String systemName = systemSettingsService.getSystemName();
        if (systemName != null) {
            return ResponseEntity.ok(systemName);
        } else {
            return ResponseEntity.notFound().build();
        }
    }

    // 获取系统版本
    @GetMapping("/systemVersion")
    public ResponseEntity<String> getSystemVersion() {
        String systemVersion = systemSettingsService.getSystemVersion();
        if (systemVersion != null) {
            return ResponseEntity.ok(systemVersion);
        } else {
            return ResponseEntity.notFound().build();
        }
    }

    // 获取系统描述
    @GetMapping("/systemDescription")
    public ResponseEntity<String> getSystemDescription() {
        String systemDescription = systemSettingsService.getSystemDescription();
        if (systemDescription != null) {
            return ResponseEntity.ok(systemDescription);
        } else {
            return ResponseEntity.notFound().build();
        }
    }

    // 获取版权信息
    @GetMapping("/copyrightInfo")
    public ResponseEntity<String> getCopyrightInfo() {
        String copyrightInfo = systemSettingsService.getCopyrightInfo();
        if (copyrightInfo != null) {
            return ResponseEntity.ok(copyrightInfo);
        } else {
            return ResponseEntity.notFound().build();
        }
    }

    // 获取存储路径
    @GetMapping("/storagePath")
    public ResponseEntity<String> getStoragePath() {
        String storagePath = systemSettingsService.getStoragePath();
        if (storagePath != null) {
            return ResponseEntity.ok(storagePath);
        } else {
            return ResponseEntity.notFound().build();
        }
    }

    // 获取登录超时时间
    @GetMapping("/loginTimeout")
    public ResponseEntity<Integer> getLoginTimeout() {
        int loginTimeout = systemSettingsService.getLoginTimeout();
        return ResponseEntity.ok(loginTimeout);
    }

    // 获取会话超时时间
    @GetMapping("/sessionTimeout")
    public ResponseEntity<Integer> getSessionTimeout() {
        int sessionTimeout = systemSettingsService.getSessionTimeout();
        return ResponseEntity.ok(sessionTimeout);
    }

    // 获取日期格式
    @GetMapping("/dateFormat")
    public ResponseEntity<String> getDateFormat() {
        String dateFormat = systemSettingsService.getDateFormat();
        if (dateFormat != null) {
            return ResponseEntity.ok(dateFormat);
        } else {
            return ResponseEntity.notFound().build();
        }
    }

    // 获取每页显示条数
    @GetMapping("/pageSize")
    public ResponseEntity<Integer> getPageSize() {
        int pageSize = systemSettingsService.getPageSize();
        return ResponseEntity.ok(pageSize);
    }

    // 获取SMTP服务器地址
    @GetMapping("/smtpServer")
    public ResponseEntity<String> getSmtpServer() {
        String smtpServer = systemSettingsService.getSmtpServer();
        if (smtpServer != null) {
            return ResponseEntity.ok(smtpServer);
        } else {
            return ResponseEntity.notFound().build();
        }
    }

    // 获取邮件发送账号
    @GetMapping("/emailAccount")
    public ResponseEntity<String> getEmailAccount() {
        String emailAccount = systemSettingsService.getEmailAccount();
        if (emailAccount != null) {
            return ResponseEntity.ok(emailAccount);
        } else {
            return ResponseEntity.notFound().build();
        }
    }

    // 获取邮件发送密码
    @GetMapping("/emailPassword")
    public ResponseEntity<String> getEmailPassword() {
        String emailPassword = systemSettingsService.getEmailPassword();
        if (emailPassword != null) {
            return ResponseEntity.ok(emailPassword);
        } else {
            return ResponseEntity.notFound().build();
        }
    }
}
