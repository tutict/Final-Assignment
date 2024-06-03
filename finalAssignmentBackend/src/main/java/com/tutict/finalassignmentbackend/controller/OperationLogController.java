package com.tutict.finalassignmentbackend.controller;

import com.tutict.finalassignmentbackend.entity.OperationLog;
import com.tutict.finalassignmentbackend.service.OperationLogService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Date;
import java.util.List;

@RestController
@RequestMapping("/eventbus/operationLogs")
public class OperationLogController {

    private final OperationLogService operationLogService;

    @Autowired
    public OperationLogController(OperationLogService operationLogService) {
        this.operationLogService = operationLogService;
    }

    @PostMapping
    public ResponseEntity<Void> createOperationLog(@RequestBody OperationLog operationLog) {
        operationLogService.createOperationLog(operationLog);
        return ResponseEntity.status(HttpStatus.CREATED).build();
    }

    @GetMapping("/{logId}")
    public ResponseEntity<OperationLog> getOperationLog(@PathVariable int logId) {
        OperationLog operationLog = operationLogService.getOperationLog(logId);
        if (operationLog != null) {
            return ResponseEntity.ok(operationLog);
        } else {
            return ResponseEntity.notFound().build();
        }
    }

    @GetMapping
    public ResponseEntity<List<OperationLog>> getAllOperationLogs() {
        List<OperationLog> operationLogs = operationLogService.getAllOperationLogs();
        return ResponseEntity.ok(operationLogs);
    }

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

    @DeleteMapping("/{logId}")
    public ResponseEntity<Void> deleteOperationLog(@PathVariable int logId) {
        operationLogService.deleteOperationLog(logId);
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/timeRange")
    public ResponseEntity<List<OperationLog>> getOperationLogsByTimeRange(
            @RequestParam("startTime") @DateTimeFormat(pattern = "yyyy-MM-dd") Date startTime,
            @RequestParam("endTime") @DateTimeFormat(pattern = "yyyy-MM-dd") Date endTime) {
        List<OperationLog> operationLogs = operationLogService.getOperationLogsByTimeRange(startTime, endTime);
        return ResponseEntity.ok(operationLogs);
    }

    @GetMapping("/userId/{userId}")
    public ResponseEntity<List<OperationLog>> getOperationLogsByUserId(@PathVariable String userId) {
        List<OperationLog> operationLogs = operationLogService.getOperationLogsByUserId(userId);
        return ResponseEntity.ok(operationLogs);
    }

    @GetMapping("/result/{result}")
    public ResponseEntity<List<OperationLog>> getOperationLogsByResult(@PathVariable String result) {
        List<OperationLog> operationLogs = operationLogService.getOperationLogsByResult(result);
        return ResponseEntity.ok(operationLogs);
    }
}