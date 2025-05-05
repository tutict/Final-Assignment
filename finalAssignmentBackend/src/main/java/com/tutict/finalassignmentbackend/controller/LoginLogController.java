package com.tutict.finalassignmentbackend.controller;

import com.tutict.finalassignmentbackend.entity.LoginLog;
import com.tutict.finalassignmentbackend.service.LoginLogService;
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
@RequestMapping("/api/loginLogs")
public class LoginLogController {

    private static final Logger log = Logger.getLogger(LoginLogController.class.getName());

    private final LoginLogService loginLogService;

    public LoginLogController(LoginLogService loginLogService) {
        this.loginLogService = loginLogService;
    }

    // 创建新的登录日志 (仅 ADMIN)
    @PostMapping
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public ResponseEntity<Void> createLoginLog(@RequestBody LoginLog loginLog, @RequestParam String idempotencyKey) {
        loginLogService.checkAndInsertIdempotency(idempotencyKey, loginLog, "create");
        return ResponseEntity.status(HttpStatus.CREATED).build();
    }

    // 根据日志ID获取登录日志 (USER 和 ADMIN)
    @GetMapping("/{logId}")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public ResponseEntity<LoginLog> getLoginLog(@PathVariable int logId) {
        LoginLog loginLog = loginLogService.getLoginLog(logId);
        if (loginLog != null) {
            return ResponseEntity.ok(loginLog);
        } else {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
        }
    }

    // 获取所有登录日志 (USER 和 ADMIN)
    @GetMapping
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public ResponseEntity<List<LoginLog>> getAllLoginLogs() {
        List<LoginLog> loginLogs = loginLogService.getAllLoginLogs();
        return ResponseEntity.ok(loginLogs);
    }

    // 更新登录日志 (仅 ADMIN)
    @PutMapping("/{logId}")
    @Transactional
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<LoginLog> updateLoginLog(@PathVariable int logId, @RequestBody LoginLog updatedLoginLog, @RequestParam String idempotencyKey) {
        LoginLog existingLoginLog = loginLogService.getLoginLog(logId);
        if (existingLoginLog != null) {
            updatedLoginLog.setLogId(logId);
            loginLogService.checkAndInsertIdempotency(idempotencyKey, updatedLoginLog, "update");
            return ResponseEntity.ok(updatedLoginLog);
        } else {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
        }
    }

    // 删除指定ID的登录日志 (仅 ADMIN)
    @DeleteMapping("/{logId}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Void> deleteLoginLog(@PathVariable int logId) {
        loginLogService.deleteLoginLog(logId);
        return ResponseEntity.noContent().build();
    }

    // 根据时间范围获取登录日志 (USER 和 ADMIN)
    @GetMapping("/timeRange")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public ResponseEntity<List<LoginLog>> getLoginLogsByTimeRange(
            @RequestParam(defaultValue = "1970-01-01") Date startTime,
            @RequestParam(defaultValue = "2100-01-01") Date endTime) {
        List<LoginLog> loginLogs = loginLogService.getLoginLogsByTimeRange(startTime, endTime);
        return ResponseEntity.ok(loginLogs);
    }

    // 根据用户名获取登录日志 (USER 和 ADMIN)
    @GetMapping("/username/{username}")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public ResponseEntity<List<LoginLog>> getLoginLogsByUsername(@PathVariable String username) {
        List<LoginLog> loginLogs = loginLogService.getLoginLogsByUsername(username);
        return ResponseEntity.ok(loginLogs);
    }

    // 根据登录结果获取登录日志 (USER 和 ADMIN)
    @GetMapping("/loginResult/{loginResult}")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public ResponseEntity<List<LoginLog>> getLoginLogsByLoginResult(@PathVariable String loginResult) {
        List<LoginLog> loginLogs = loginLogService.getLoginLogsByLoginResult(loginResult);
        return ResponseEntity.ok(loginLogs);
    }

    @GetMapping("/autocomplete/usernames/me")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<List<String>> getUsernameAutocompleteSuggestionsGlobally(
            @RequestParam String prefix) {
        String decodedPrefix = URLDecoder.decode(prefix, StandardCharsets.UTF_8);
        log.log(Level.INFO, "Fetching username suggestions for prefix: {0}, decoded: {1}",
                new Object[]{prefix, decodedPrefix});

        List<String> suggestions = loginLogService.getUsernamesByPrefixGlobally(decodedPrefix);
        if (suggestions == null) {
            suggestions = Collections.emptyList();
        }

        if (suggestions.isEmpty()) {
            log.log(Level.INFO, "No username suggestions found for prefix: {0}", new Object[]{decodedPrefix});
        } else {
            log.log(Level.INFO, "Found {0} username suggestions for prefix: {1}",
                    new Object[]{suggestions.size(), decodedPrefix});
        }

        return ResponseEntity.ok(suggestions);
    }

    @GetMapping("/autocomplete/login-results/me")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<List<String>> getLoginResultAutocompleteSuggestionsGlobally(
            @RequestParam String prefix) {
        String decodedPrefix = URLDecoder.decode(prefix, StandardCharsets.UTF_8);
        log.log(Level.INFO, "Fetching login result suggestions for prefix: {0}, decoded: {1}",
                new Object[]{prefix, decodedPrefix});

        List<String> suggestions = loginLogService.getLoginResultsByPrefixGlobally(decodedPrefix);
        if (suggestions == null) {
            suggestions = Collections.emptyList();
        }

        if (suggestions.isEmpty()) {
            log.log(Level.INFO, "No login result suggestions found for prefix: {0}", new Object[]{decodedPrefix});
        } else {
            log.log(Level.INFO, "Found {0} login result suggestions for prefix: {1}",
                    new Object[]{suggestions.size(), decodedPrefix});
        }

        return ResponseEntity.ok(suggestions);
    }
}