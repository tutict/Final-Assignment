package com.tutict.finalassignmentbackend.controller;

import com.tutict.finalassignmentbackend.entity.LoginLog;
import com.tutict.finalassignmentbackend.service.LoginLogService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
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

@RestController
@RequestMapping("/eventbus/loginLogs")
public class LoginLogController {

    private final LoginLogService loginLogService;

    @Autowired
    public LoginLogController(LoginLogService loginLogService) {
        this.loginLogService = loginLogService;
    }

    @PostMapping
    public ResponseEntity<Void> createLoginLog(@RequestBody LoginLog loginLog) {
        loginLogService.createLoginLog(loginLog);
        return ResponseEntity.status(HttpStatus.CREATED).build();
    }

    @GetMapping("/{logId}")
    public ResponseEntity<LoginLog> getLoginLog(@PathVariable int logId) {
        LoginLog loginLog = loginLogService.getLoginLog(logId);
        if (loginLog != null) {
            return ResponseEntity.ok(loginLog);
        } else {
            return ResponseEntity.notFound().build();
        }
    }

    @GetMapping
    public ResponseEntity<List<LoginLog>> getAllLoginLogs() {
        List<LoginLog> loginLogs = loginLogService.getAllLoginLogs();
        return ResponseEntity.ok(loginLogs);
    }

    @PutMapping("/{logId}")
    public ResponseEntity<Void> updateLoginLog(@PathVariable int logId, @RequestBody LoginLog updatedLoginLog) {
        LoginLog existingLoginLog = loginLogService.getLoginLog(logId);
        if (existingLoginLog != null) {
            updatedLoginLog.setLogId(logId);
            loginLogService.updateLoginLog(updatedLoginLog);
            return ResponseEntity.ok().build();
        } else {
            return ResponseEntity.notFound().build();
        }
    }

    @DeleteMapping("/{logId}")
    public ResponseEntity<Void> deleteLoginLog(@PathVariable int logId) {
        loginLogService.deleteLoginLog(logId);
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/timeRange")
    public ResponseEntity<List<LoginLog>> getLoginLogsByTimeRange(
            @RequestParam("startTime") @DateTimeFormat(pattern = "yyyy-MM-dd") Date startTime,
            @RequestParam("endTime") @DateTimeFormat(pattern = "yyyy-MM-dd") Date endTime) {
        List<LoginLog> loginLogs = loginLogService.getLoginLogsByTimeRange(startTime, endTime);
        return ResponseEntity.ok(loginLogs);
    }

    @GetMapping("/username/{username}")
    public ResponseEntity<List<LoginLog>> getLoginLogsByUsername(@PathVariable String username) {
        List<LoginLog> loginLogs = loginLogService.getLoginLogsByUsername(username);
        return ResponseEntity.ok(loginLogs);
    }

    @GetMapping("/loginResult/{loginResult}")
    public ResponseEntity<List<LoginLog>> getLoginLogsByLoginResult(@PathVariable String loginResult) {
        List<LoginLog> loginLogs = loginLogService.getLoginLogsByLoginResult(loginResult);
        return ResponseEntity.ok(loginLogs);
    }
}