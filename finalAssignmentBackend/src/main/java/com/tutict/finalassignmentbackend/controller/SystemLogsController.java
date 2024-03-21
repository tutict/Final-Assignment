package com.tutict.finalassignmentbackend.controller;

import com.tutict.finalassignmentbackend.entity.SystemLogs;
import com.tutict.finalassignmentbackend.service.SystemLogsService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Date;
import java.util.List;

@RestController
@RequestMapping("/api/systemLogs")
public class SystemLogsController {

    private final SystemLogsService systemLogsService;

    @Autowired
    public SystemLogsController(SystemLogsService systemLogsService) {
        this.systemLogsService = systemLogsService;
    }

    @PostMapping
    public ResponseEntity<Void> createSystemLog(@RequestBody SystemLogs systemLog) {
        systemLogsService.createSystemLog(systemLog);
        return ResponseEntity.status(HttpStatus.CREATED).build();
    }

    @GetMapping("/{logId}")
    public ResponseEntity<SystemLogs> getSystemLogById(@PathVariable int logId) {
        SystemLogs systemLog = systemLogsService.getSystemLogById(logId);
        if (systemLog != null) {
            return ResponseEntity.ok(systemLog);
        } else {
            return ResponseEntity.notFound().build();
        }
    }

    @GetMapping
    public ResponseEntity<List<SystemLogs>> getAllSystemLogs() {
        List<SystemLogs> systemLogs = systemLogsService.getAllSystemLogs();
        return ResponseEntity.ok(systemLogs);
    }

    @GetMapping("/type/{logType}")
    public ResponseEntity<List<SystemLogs>> getSystemLogsByType(@PathVariable String logType) {
        List<SystemLogs> systemLogs = systemLogsService.getSystemLogsByType(logType);
        return ResponseEntity.ok(systemLogs);
    }

    @GetMapping("/timeRange")
    public ResponseEntity<List<SystemLogs>> getSystemLogsByTimeRange(
            @RequestParam("startTime") @DateTimeFormat(pattern = "yyyy-MM-dd HH:mm:ss") Date startTime,
            @RequestParam("endTime") @DateTimeFormat(pattern = "yyyy-MM-dd HH:mm:ss") Date endTime) {
        List<SystemLogs> systemLogs = systemLogsService.getSystemLogsByTimeRange(startTime, endTime);
        return ResponseEntity.ok(systemLogs);
    }

    @GetMapping("/operationUser/{operationUser}")
    public ResponseEntity<List<SystemLogs>> getSystemLogsByOperationUser(@PathVariable String operationUser) {
        List<SystemLogs> systemLogs = systemLogsService.getSystemLogsByOperationUser(operationUser);
        return ResponseEntity.ok(systemLogs);
    }

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

    @DeleteMapping("/{logId}")
    public ResponseEntity<Void> deleteSystemLog(@PathVariable int logId) {
        systemLogsService.deleteSystemLog(logId);
        return ResponseEntity.noContent().build();
    }
}