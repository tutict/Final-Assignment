package com.tutict.finalassignmentbackend.controller;

import com.tutict.finalassignmentbackend.entity.AuditLoginLog;
import com.tutict.finalassignmentbackend.service.AuditLoginLogService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.annotation.security.RolesAllowed;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;

@RestController
@RequestMapping("/api/logs/login")
@Tag(name = "Login Audit", description = "系统登录日志管理接口")
@SecurityRequirement(name = "bearerAuth")
@RolesAllowed({"SUPER_ADMIN", "ADMIN"})
public class LoginLogController {

    private static final Logger LOG = Logger.getLogger(LoginLogController.class.getName());

    private final AuditLoginLogService auditLoginLogService;

    public LoginLogController(AuditLoginLogService auditLoginLogService) {
        this.auditLoginLogService = auditLoginLogService;
    }

    @PostMapping
    @Operation(summary = "写入登录日志")
    public ResponseEntity<AuditLoginLog> create(@RequestBody AuditLoginLog request,
                                                @RequestHeader(value = "Idempotency-Key", required = false)
                                                String idempotencyKey) {
        boolean useKey = hasKey(idempotencyKey);
        try {
            if (useKey) {
                if (auditLoginLogService.shouldSkipProcessing(idempotencyKey)) {
                    return ResponseEntity.status(HttpStatus.ALREADY_REPORTED).build();
                }
                auditLoginLogService.checkAndInsertIdempotency(idempotencyKey, request, "create");
            }
            AuditLoginLog saved = auditLoginLogService.createAuditLoginLog(request);
            if (useKey && saved.getLogId() != null) {
                auditLoginLogService.markHistorySuccess(idempotencyKey, saved.getLogId());
            }
            return ResponseEntity.status(HttpStatus.CREATED).body(saved);
        } catch (Exception ex) {
            if (useKey) {
                auditLoginLogService.markHistoryFailure(idempotencyKey, ex.getMessage());
            }
            LOG.log(Level.SEVERE, "Create login log failed", ex);
            return ResponseEntity.status(resolveStatus(ex)).build();
        }
    }

    @PutMapping("/{logId}")
    @Operation(summary = "更新登录日志")
    public ResponseEntity<AuditLoginLog> update(@PathVariable Long logId,
                                                @RequestBody AuditLoginLog request,
                                                @RequestHeader(value = "Idempotency-Key", required = false)
                                                String idempotencyKey) {
        boolean useKey = hasKey(idempotencyKey);
        try {
            request.setLogId(logId);
            if (useKey) {
                auditLoginLogService.checkAndInsertIdempotency(idempotencyKey, request, "update");
            }
            AuditLoginLog updated = auditLoginLogService.updateAuditLoginLog(request);
            if (useKey && updated.getLogId() != null) {
                auditLoginLogService.markHistorySuccess(idempotencyKey, updated.getLogId());
            }
            return ResponseEntity.ok(updated);
        } catch (Exception ex) {
            if (useKey) {
                auditLoginLogService.markHistoryFailure(idempotencyKey, ex.getMessage());
            }
            LOG.log(Level.SEVERE, "Update login log failed", ex);
            return ResponseEntity.status(resolveStatus(ex)).build();
        }
    }

    @DeleteMapping("/{logId}")
    @Operation(summary = "删除登录日志")
    public ResponseEntity<Void> delete(@PathVariable Long logId) {
        try {
            auditLoginLogService.deleteAuditLoginLog(logId);
            return ResponseEntity.noContent().build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Delete login log failed", ex);
            return ResponseEntity.status(resolveStatus(ex)).build();
        }
    }

    @GetMapping("/{logId}")
    @Operation(summary = "查询登录日志详情")
    public ResponseEntity<AuditLoginLog> get(@PathVariable Long logId) {
        try {
            AuditLoginLog log = auditLoginLogService.findById(logId);
            return log == null ? ResponseEntity.notFound().build() : ResponseEntity.ok(log);
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Get login log failed", ex);
            return ResponseEntity.status(resolveStatus(ex)).build();
        }
    }

    @GetMapping
    @Operation(summary = "查询全部登录日志")
    public ResponseEntity<List<AuditLoginLog>> list() {
        try {
            return ResponseEntity.ok(auditLoginLogService.findAll());
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "List login logs failed", ex);
            return ResponseEntity.status(resolveStatus(ex)).build();
        }
    }

    @GetMapping("/search/username")
    @Operation(summary = "按用户名搜索登录日志")
    public ResponseEntity<List<AuditLoginLog>> searchByUsername(@RequestParam String username,
                                                                @RequestParam(defaultValue = "1") int page,
                                                                @RequestParam(defaultValue = "20") int size) {
        try {
            return ResponseEntity.ok(auditLoginLogService.searchByUsername(username, page, size));
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Search login log by username failed", ex);
            return ResponseEntity.status(resolveStatus(ex)).build();
        }
    }

    @GetMapping("/search/result")
    @Operation(summary = "按登录结果搜索")
    public ResponseEntity<List<AuditLoginLog>> searchByResult(@RequestParam String result,
                                                              @RequestParam(defaultValue = "1") int page,
                                                              @RequestParam(defaultValue = "20") int size) {
        try {
            return ResponseEntity.ok(auditLoginLogService.searchByLoginResult(result, page, size));
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Search login log by result failed", ex);
            return ResponseEntity.status(resolveStatus(ex)).build();
        }
    }

    @GetMapping("/search/time-range")
    @Operation(summary = "按登录时间范围搜索")
    public ResponseEntity<List<AuditLoginLog>> searchByTimeRange(@RequestParam String startTime,
                                                                 @RequestParam String endTime,
                                                                 @RequestParam(defaultValue = "1") int page,
                                                                 @RequestParam(defaultValue = "20") int size) {
        try {
            return ResponseEntity.ok(auditLoginLogService.searchByLoginTimeRange(startTime, endTime, page, size));
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Search login log by time range failed", ex);
            return ResponseEntity.status(resolveStatus(ex)).build();
        }
    }

    @GetMapping("/search/ip")
    @Operation(summary = "按登录 IP 搜索")
    public ResponseEntity<List<AuditLoginLog>> searchByIp(@RequestParam String ip,
                                                          @RequestParam(defaultValue = "1") int page,
                                                          @RequestParam(defaultValue = "20") int size) {
        try {
            return ResponseEntity.ok(auditLoginLogService.searchByLoginIp(ip, page, size));
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Search login log by IP failed", ex);
            return ResponseEntity.status(resolveStatus(ex)).build();
        }
    }

    private boolean hasKey(String value) {
        return value != null && !value.isBlank();
    }

    private HttpStatus resolveStatus(Exception ex) {
        return (ex instanceof IllegalArgumentException || ex instanceof IllegalStateException)
                ? HttpStatus.BAD_REQUEST
                : HttpStatus.INTERNAL_SERVER_ERROR;
    }
}
