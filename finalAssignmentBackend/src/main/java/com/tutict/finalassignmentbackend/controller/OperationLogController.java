package com.tutict.finalassignmentbackend.controller;

import com.tutict.finalassignmentbackend.entity.OperationLog;
import com.tutict.finalassignmentbackend.service.OperationLogService;
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

// 控制器类，用于管理操作日志的CRUD操作
@RestController
@RequestMapping("/eventbus/operationLogs")
public class OperationLogController {

    // 操作日志服务的接口实例
    private final OperationLogService operationLogService;

    // 构造函数，通过依赖注入初始化操作日志服务实例
    @Autowired
    public OperationLogController(OperationLogService operationLogService) {
        this.operationLogService = operationLogService;
    }

    // 创建操作日志的接口
    @PostMapping
    public ResponseEntity<Void> createOperationLog(@RequestBody OperationLog operationLog) {
        operationLogService.createOperationLog(operationLog);
        return ResponseEntity.status(HttpStatus.CREATED).build();
    }

    // 根据日志ID获取操作日志的接口
    @GetMapping("/{logId}")
    public ResponseEntity<OperationLog> getOperationLog(@PathVariable int logId) {
        OperationLog operationLog = operationLogService.getOperationLog(logId);
        if (operationLog != null) {
            return ResponseEntity.ok(operationLog);
        } else {
            return ResponseEntity.notFound().build();
        }
    }

    // 获取所有操作日志的接口
    @GetMapping
    public ResponseEntity<List<OperationLog>> getAllOperationLogs() {
        List<OperationLog> operationLogs = operationLogService.getAllOperationLogs();
        return ResponseEntity.ok(operationLogs);
    }

    // 更新操作日志的接口
    @PutMapping("/{logId}")
    public ResponseEntity<Void> updateOperationLog(@PathVariable int logId, @RequestBody OperationLog updatedOperationLog) {
        OperationLog existingOperationLog = operationLogService.getOperationLog(logId);
        if (existingOperationLog != null) {
            updatedOperationLog.setLogId(logId);
            operationLogService.updateOperationLog(updatedOperationLog);
            return ResponseEntity.ok().build();
        } else {
            return ResponseEntity.notFound().build();
        }
    }

    // 删除操作日志的接口
    @DeleteMapping("/{logId}")
    public ResponseEntity<Void> deleteOperationLog(@PathVariable int logId) {
        operationLogService.deleteOperationLog(logId);
        return ResponseEntity.noContent().build();
    }

    // 根据时间范围获取操作日志的接口
    @GetMapping("/timeRange")
    public ResponseEntity<List<OperationLog>> getOperationLogsByTimeRange(
            @RequestParam("startTime") @DateTimeFormat(pattern = "yyyy-MM-dd") Date startTime,
            @RequestParam("endTime") @DateTimeFormat(pattern = "yyyy-MM-dd") Date endTime) {
        List<OperationLog> operationLogs = operationLogService.getOperationLogsByTimeRange(startTime, endTime);
        return ResponseEntity.ok(operationLogs);
    }

    // 根据用户ID获取操作日志的接口
    @GetMapping("/userId/{userId}")
    public ResponseEntity<List<OperationLog>> getOperationLogsByUserId(@PathVariable String userId) {
        List<OperationLog> operationLogs = operationLogService.getOperationLogsByUserId(userId);
        return ResponseEntity.ok(operationLogs);
    }

    // 根据操作结果获取操作日志的接口
    @GetMapping("/result/{result}")
    public ResponseEntity<List<OperationLog>> getOperationLogsByResult(@PathVariable String result) {
        List<OperationLog> operationLogs = operationLogService.getOperationLogsByResult(result);
        return ResponseEntity.ok(operationLogs);
    }
}
