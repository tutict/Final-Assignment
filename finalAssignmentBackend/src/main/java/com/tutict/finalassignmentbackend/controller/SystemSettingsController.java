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

@RestController
@RequestMapping("/eventbus/systemSettings")
public class SystemSettingsController {

    private final SystemSettingsService systemSettingsService;

    @Autowired
    public SystemSettingsController(SystemSettingsService systemSettingsService) {
        this.systemSettingsService = systemSettingsService;
    }

    @GetMapping
    public ResponseEntity<SystemSettings> getSystemSettings() {
        SystemSettings systemSettings = systemSettingsService.getSystemSettings();
        if (systemSettings != null) {
            return ResponseEntity.ok(systemSettings);
        } else {
            return ResponseEntity.notFound().build();
        }
    }

    @PutMapping
    public ResponseEntity<Void> updateSystemSettings(@RequestBody SystemSettings systemSettings) {
        systemSettingsService.updateSystemSettings(systemSettings);
        return ResponseEntity.ok().build();
    }

    @GetMapping("/systemName")
    public ResponseEntity<String> getSystemName() {
        String systemName = systemSettingsService.getSystemName();
        if (systemName != null) {
            return ResponseEntity.ok(systemName);
        } else {
            return ResponseEntity.notFound().build();
        }
    }

    @GetMapping("/systemVersion")
    public ResponseEntity<String> getSystemVersion() {
        String systemVersion = systemSettingsService.getSystemVersion();
        if (systemVersion != null) {
            return ResponseEntity.ok(systemVersion);
        } else {
            return ResponseEntity.notFound().build();
        }
    }

    @GetMapping("/systemDescription")
    public ResponseEntity<String> getSystemDescription() {
        String systemDescription = systemSettingsService.getSystemDescription();
        if (systemDescription != null) {
            return ResponseEntity.ok(systemDescription);
        } else {
            return ResponseEntity.notFound().build();
        }
    }

    @GetMapping("/copyrightInfo")
    public ResponseEntity<String> getCopyrightInfo() {
        String copyrightInfo = systemSettingsService.getCopyrightInfo();
        if (copyrightInfo != null) {
            return ResponseEntity.ok(copyrightInfo);
        } else {
            return ResponseEntity.notFound().build();
        }
    }

    @GetMapping("/storagePath")
    public ResponseEntity<String> getStoragePath() {
        String storagePath = systemSettingsService.getStoragePath();
        if (storagePath != null) {
            return ResponseEntity.ok(storagePath);
        } else {
            return ResponseEntity.notFound().build();
        }
    }

    @GetMapping("/loginTimeout")
    public ResponseEntity<Integer> getLoginTimeout() {
        int loginTimeout = systemSettingsService.getLoginTimeout();
        return ResponseEntity.ok(loginTimeout);
    }

    @GetMapping("/sessionTimeout")
    public ResponseEntity<Integer> getSessionTimeout() {
        int sessionTimeout = systemSettingsService.getSessionTimeout();
        return ResponseEntity.ok(sessionTimeout);
    }

    @GetMapping("/dateFormat")
    public ResponseEntity<String> getDateFormat() {
        String dateFormat = systemSettingsService.getDateFormat();
        if (dateFormat != null) {
            return ResponseEntity.ok(dateFormat);
        } else {
            return ResponseEntity.notFound().build();
        }
    }

    @GetMapping("/pageSize")
    public ResponseEntity<Integer> getPageSize() {
        int pageSize = systemSettingsService.getPageSize();
        return ResponseEntity.ok(pageSize);
    }

    @GetMapping("/smtpServer")
    public ResponseEntity<String> getSmtpServer() {
        String smtpServer = systemSettingsService.getSmtpServer();
        if (smtpServer != null) {
            return ResponseEntity.ok(smtpServer);
        } else {
            return ResponseEntity.notFound().build();
        }
    }

    @GetMapping("/emailAccount")
    public ResponseEntity<String> getEmailAccount() {
        String emailAccount = systemSettingsService.getEmailAccount();
        if (emailAccount != null) {
            return ResponseEntity.ok(emailAccount);
        } else {
            return ResponseEntity.notFound().build();
        }
    }

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
