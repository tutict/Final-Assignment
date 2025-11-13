package com.tutict.finalassignmentbackend.controller;

import com.tutict.finalassignmentbackend.entity.AuditLoginLog;
import com.tutict.finalassignmentbackend.entity.AuditOperationLog;
import com.tutict.finalassignmentbackend.entity.SysRequestHistory;
import com.tutict.finalassignmentbackend.service.AuditLoginLogService;
import com.tutict.finalassignmentbackend.service.AuditOperationLogService;
import com.tutict.finalassignmentbackend.service.SysRequestHistoryService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.annotation.security.RolesAllowed;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.logging.Level;
import java.util.logging.Logger;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/system/logs")
@Tag(name = "System Logs", description = "系统日志汇总查询接口")
@SecurityRequirement(name = "bearerAuth")
@RolesAllowed({"SUPER_ADMIN", "ADMIN"})
public class SystemLogsController {

    private static final Logger LOG = Logger.getLogger(SystemLogsController.class.getName());

    private final AuditLoginLogService auditLoginLogService;
    private final AuditOperationLogService auditOperationLogService;
    private final SysRequestHistoryService sysRequestHistoryService;

    public SystemLogsController(AuditLoginLogService auditLoginLogService,
                                AuditOperationLogService auditOperationLogService,
                                SysRequestHistoryService sysRequestHistoryService) {
        this.auditLoginLogService = auditLoginLogService;
        this.auditOperationLogService = auditOperationLogService;
        this.sysRequestHistoryService = sysRequestHistoryService;
    }

    @GetMapping("/overview")
    @Operation(summary = "获取系统日志概览")
    public ResponseEntity<Map<String, Object>> overview() {
        try {
            Map<String, Object> result = new HashMap<>();
            result.put("loginLogCount", auditLoginLogService.findAll().size());
            result.put("operationLogCount", auditOperationLogService.findAll().size());
            result.put("requestHistoryCount", sysRequestHistoryService.findAll().size());
            return ResponseEntity.ok(result);
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Fetch log overview failed", ex);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    @GetMapping("/login/recent")
    @Operation(summary = "最近的登录日志")
    public ResponseEntity<List<AuditLoginLog>> recentLoginLogs(@RequestParam(defaultValue = "10") int limit) {
        try {
            List<AuditLoginLog> recent = auditLoginLogService.findAll().stream()
                    .limit(Math.max(limit, 1))
                    .collect(Collectors.toList());
            return ResponseEntity.ok(recent);
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Fetch recent login logs failed", ex);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    @GetMapping("/operation/recent")
    @Operation(summary = "最近的操作日志")
    public ResponseEntity<List<AuditOperationLog>> recentOperationLogs(@RequestParam(defaultValue = "10") int limit) {
        try {
            List<AuditOperationLog> recent = auditOperationLogService.findAll().stream()
                    .limit(Math.max(limit, 1))
                    .collect(Collectors.toList());
            return ResponseEntity.ok(recent);
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Fetch recent operation logs failed", ex);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    @GetMapping("/requests/{historyId}")
    @Operation(summary = "查询幂等请求进度详情")
    public ResponseEntity<SysRequestHistory> requestHistory(@PathVariable Long historyId) {
        try {
            SysRequestHistory history = sysRequestHistoryService.findById(historyId);
            return history == null ? ResponseEntity.notFound().build() : ResponseEntity.ok(history);
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Fetch request history failed", ex);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }
}
