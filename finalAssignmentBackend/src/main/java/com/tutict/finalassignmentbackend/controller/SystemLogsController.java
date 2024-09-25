package com.tutict.finalassignmentbackend.controller;

import com.tutict.finalassignmentbackend.entity.SystemLogs;
import com.tutict.finalassignmentbackend.service.SystemLogsService;
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

// 控制器类，处理与系统日志相关的HTTP请求
@RestController
@RequestMapping("/eventbus/systemLogs")
public class SystemLogsController {

    // 系统日志服务的接口实例，用于处理日志的业务逻辑
    private final SystemLogsService systemLogsService;

    // 构造函数，通过依赖注入初始化系统日志服务实例
    @Autowired
    public SystemLogsController(SystemLogsService systemLogsService) {
        this.systemLogsService = systemLogsService;
    }

    // 创建系统日志的接口，接收POST请求
    @PostMapping
    public ResponseEntity<Void> createSystemLog(@RequestBody SystemLogs systemLog) {
        systemLogsService.createSystemLog(systemLog);
        return ResponseEntity.status(HttpStatus.CREATED).build();
    }

    // 根据日志ID获取系统日志的接口，接收GET请求
    @GetMapping("/{logId}")
    public ResponseEntity<SystemLogs> getSystemLogById(@PathVariable int logId) {
        SystemLogs systemLog = systemLogsService.getSystemLogById(logId);
        if (systemLog != null) {
            return ResponseEntity.ok(systemLog);
        } else {
            return ResponseEntity.notFound().build();
        }
    }

    // 获取所有系统日志的接口，接收GET请求
    @GetMapping
    public ResponseEntity<List<SystemLogs>> getAllSystemLogs() {
        List<SystemLogs> systemLogs = systemLogsService.getAllSystemLogs();
        return ResponseEntity.ok(systemLogs);
    }

    // 根据日志类型获取系统日志的接口，接收GET请求
    @GetMapping("/type/{logType}")
    public ResponseEntity<List<SystemLogs>> getSystemLogsByType(@PathVariable String logType) {
        List<SystemLogs> systemLogs = systemLogsService.getSystemLogsByType(logType);
        return ResponseEntity.ok(systemLogs);
    }

    // 根据时间范围获取系统日志的接口，接收GET请求
    @GetMapping("/timeRange")
    public ResponseEntity<List<SystemLogs>> getSystemLogsByTimeRange(
            @RequestParam("startTime") @DateTimeFormat(pattern = "yyyy-MM-dd HH:mm:ss") Date startTime,
            @RequestParam("endTime") @DateTimeFormat(pattern = "yyyy-MM-dd HH:mm:ss") Date endTime) {
        List<SystemLogs> systemLogs = systemLogsService.getSystemLogsByTimeRange(startTime, endTime);
        return ResponseEntity.ok(systemLogs);
    }

    // 根据操作用户获取系统日志的接口，接收GET请求
    @GetMapping("/operationUser/{operationUser}")
    public ResponseEntity<List<SystemLogs>> getSystemLogsByOperationUser(@PathVariable String operationUser) {
        List<SystemLogs> systemLogs = systemLogsService.getSystemLogsByOperationUser(operationUser);
        return ResponseEntity.ok(systemLogs);
    }

    // 更新系统日志的接口，接收PUT请求
    @PutMapping("/{logId}")
    public ResponseEntity<Void> updateSystemLog(@PathVariable int logId, @RequestBody SystemLogs updatedSystemLog) {
        SystemLogs existingSystemLog = systemLogsService.getSystemLogById(logId);
        if (existingSystemLog != null) {
            updatedSystemLog.setLogId(logId);
            systemLogsService.updateSystemLog(updatedSystemLog);
            return ResponseEntity.ok().build();
        } else {
            return ResponseEntity.notFound().build();
        }
    }

    // 删除系统日志的接口，接收DELETE请求
    @DeleteMapping("/{logId}")
    public ResponseEntity<Void> deleteSystemLog(@PathVariable int logId) {
        systemLogsService.deleteSystemLog(logId);
        return ResponseEntity.noContent().build();
    }
}
