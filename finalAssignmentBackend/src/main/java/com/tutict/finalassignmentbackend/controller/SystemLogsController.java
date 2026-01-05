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

    @GetMapping("/requests/search/idempotency")
    @Operation(summary = "Search request history by idempotency key")
    public ResponseEntity<List<SysRequestHistory>> searchByIdempotency(@RequestParam String key,
                                                                       @RequestParam(defaultValue = "1") int page,
                                                                       @RequestParam(defaultValue = "20") int size) {
        return ResponseEntity.ok(sysRequestHistoryService.searchByIdempotencyKey(key, page, size));
    }

    @GetMapping("/requests/search/method")
    @Operation(summary = "Search request history by request method")
    public ResponseEntity<List<SysRequestHistory>> searchByRequestMethod(@RequestParam String requestMethod,
                                                                         @RequestParam(defaultValue = "1") int page,
                                                                         @RequestParam(defaultValue = "20") int size) {
        return ResponseEntity.ok(sysRequestHistoryService.searchByRequestMethod(requestMethod, page, size));
    }

    @GetMapping("/requests/search/url")
    @Operation(summary = "Search request history by request URL prefix")
    public ResponseEntity<List<SysRequestHistory>> searchByRequestUrl(@RequestParam String requestUrl,
                                                                      @RequestParam(defaultValue = "1") int page,
                                                                      @RequestParam(defaultValue = "20") int size) {
        return ResponseEntity.ok(sysRequestHistoryService.searchByRequestUrlPrefix(requestUrl, page, size));
    }

    @GetMapping("/requests/search/business-type")
    @Operation(summary = "Search request history by business type")
    public ResponseEntity<List<SysRequestHistory>> searchByBusinessType(@RequestParam String businessType,
                                                                        @RequestParam(defaultValue = "1") int page,
                                                                        @RequestParam(defaultValue = "20") int size) {
        return ResponseEntity.ok(sysRequestHistoryService.searchByBusinessType(businessType, page, size));
    }

    @GetMapping("/requests/search/business-id")
    @Operation(summary = "Search request history by business id")
    public ResponseEntity<List<SysRequestHistory>> searchByBusinessId(@RequestParam Long businessId,
                                                                      @RequestParam(defaultValue = "1") int page,
                                                                      @RequestParam(defaultValue = "20") int size) {
        return ResponseEntity.ok(sysRequestHistoryService.findByBusinessId(businessId, page, size));
    }

    @GetMapping("/requests/search/status")
    @Operation(summary = "Search request history by business status")
    public ResponseEntity<List<SysRequestHistory>> searchByBusinessStatus(@RequestParam String status,
                                                                          @RequestParam(defaultValue = "1") int page,
                                                                          @RequestParam(defaultValue = "20") int size) {
        return ResponseEntity.ok(sysRequestHistoryService.findByBusinessStatus(status, page, size));
    }

    @GetMapping("/requests/search/user")
    @Operation(summary = "Search request history by user id")
    public ResponseEntity<List<SysRequestHistory>> searchByUser(@RequestParam Long userId,
                                                                @RequestParam(defaultValue = "1") int page,
                                                                @RequestParam(defaultValue = "20") int size) {
        return ResponseEntity.ok(sysRequestHistoryService.findByUserId(userId, page, size));
    }

    @GetMapping("/requests/search/ip")
    @Operation(summary = "Search request history by request IP")
    public ResponseEntity<List<SysRequestHistory>> searchByRequestIp(@RequestParam String requestIp,
                                                                     @RequestParam(defaultValue = "1") int page,
                                                                     @RequestParam(defaultValue = "20") int size) {
        return ResponseEntity.ok(sysRequestHistoryService.searchByRequestIp(requestIp, page, size));
    }

    @GetMapping("/requests/search/time-range")
    @Operation(summary = "Search request history by created time range")
    public ResponseEntity<List<SysRequestHistory>> searchByCreatedTimeRange(@RequestParam String startTime,
                                                                            @RequestParam String endTime,
                                                                            @RequestParam(defaultValue = "1") int page,
                                                                            @RequestParam(defaultValue = "20") int size) {
        return ResponseEntity.ok(sysRequestHistoryService.searchByCreatedAtRange(startTime, endTime, page, size));
    }
}
