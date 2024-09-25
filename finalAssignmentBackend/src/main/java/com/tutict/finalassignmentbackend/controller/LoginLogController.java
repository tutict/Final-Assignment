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

// 控制器类，用于处理与登录日志相关的HTTP请求
@RestController
@RequestMapping("/eventbus/loginLogs")
public class LoginLogController {

    // 登录日志服务层的接口实例，用于操作登录日志数据
    private final LoginLogService loginLogService;

    // 构造函数，通过依赖注入初始化登录日志服务层的实例
    @Autowired
    public LoginLogController(LoginLogService loginLogService) {
        this.loginLogService = loginLogService;
    }

    // 创建登录日志的接口，接收POST请求
    // 请求体中的LoginLog对象包含新登录日志的详细信息
    @PostMapping
    public ResponseEntity<Void> createLoginLog(@RequestBody LoginLog loginLog) {
        loginLogService.createLoginLog(loginLog);
        return ResponseEntity.status(HttpStatus.CREATED).build();
    }

    // 根据日志ID获取登录日志的接口，接收GET请求
    // {logId}是一个路径变量，代表登录日志的唯一标识符
    @GetMapping("/{logId}")
    public ResponseEntity<LoginLog> getLoginLog(@PathVariable int logId) {
        LoginLog loginLog = loginLogService.getLoginLog(logId);
        if (loginLog != null) {
            return ResponseEntity.ok(loginLog);
        } else {
            return ResponseEntity.notFound().build();
        }
    }

    // 获取所有登录日志的接口，接收GET请求
    // 该接口返回一个登录日志的列表
    @GetMapping
    public ResponseEntity<List<LoginLog>> getAllLoginLogs() {
        List<LoginLog> loginLogs = loginLogService.getAllLoginLogs();
        return ResponseEntity.ok(loginLogs);
    }

    // 更新登录日志的接口，接收PUT请求
    // {logId}是一个路径变量，代表要更新的登录日志的ID
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

    // 删除登录日志的接口，接收DELETE请求
    // {logId}是一个路径变量，代表要删除的登录日志的ID
    @DeleteMapping("/{logId}")
    public ResponseEntity<Void> deleteLoginLog(@PathVariable int logId) {
        loginLogService.deleteLoginLog(logId);
        return ResponseEntity.noContent().build();
    }

    // 根据时间范围获取登录日志的接口，接收GET请求
    // startTime和endTime是查询参数，用于指定时间筛选范围
    @GetMapping("/timeRange")
    public ResponseEntity<List<LoginLog>> getLoginLogsByTimeRange(
            @RequestParam("startTime") @DateTimeFormat(pattern = "yyyy-MM-dd") Date startTime,
            @RequestParam("endTime") @DateTimeFormat(pattern = "yyyy-MM-dd") Date endTime) {
        List<LoginLog> loginLogs = loginLogService.getLoginLogsByTimeRange(startTime, endTime);
        return ResponseEntity.ok(loginLogs);
    }

    // 根据用户名获取登录日志的接口，接收GET请求
    // {username}是一个路径变量，代表查询的用户名
    @GetMapping("/username/{username}")
    public ResponseEntity<List<LoginLog>> getLoginLogsByUsername(@PathVariable String username) {
        List<LoginLog> loginLogs = loginLogService.getLoginLogsByUsername(username);
        return ResponseEntity.ok(loginLogs);
    }

    // 根据登录结果获取登录日志的接口，接收GET请求
    // {loginResult}是一个路径变量，代表查询的登录结果（成功或失败）
    @GetMapping("/loginResult/{loginResult}")
    public ResponseEntity<List<LoginLog>> getLoginLogsByLoginResult(@PathVariable String loginResult) {
        List<LoginLog> loginLogs = loginLogService.getLoginLogsByLoginResult(loginResult);
        return ResponseEntity.ok(loginLogs);
    }
}
