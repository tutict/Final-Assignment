package com.tutict.finalassignmentbackend.controller;

import com.tutict.finalassignmentbackend.entity.SysRequestHistory;
import com.tutict.finalassignmentbackend.service.SysRequestHistoryService;
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
import java.util.Optional;
import java.util.logging.Level;
import java.util.logging.Logger;

@RestController
@RequestMapping("/api/progress")
@Tag(name = "Progress Tracker", description = "幂等请求进度跟踪接口")
@SecurityRequirement(name = "bearerAuth")
@RolesAllowed({"SUPER_ADMIN", "ADMIN"})
public class ProgressItemController {

    private static final Logger LOG = Logger.getLogger(ProgressItemController.class.getName());

    private final SysRequestHistoryService sysRequestHistoryService;

    public ProgressItemController(SysRequestHistoryService sysRequestHistoryService) {
        this.sysRequestHistoryService = sysRequestHistoryService;
    }

    @PostMapping
    @Operation(summary = "创建进度记录")
    public ResponseEntity<SysRequestHistory> create(@RequestBody SysRequestHistory request,
                                                    @RequestHeader(value = "Idempotency-Key", required = false)
                                                    String idempotencyKey) {
        boolean useKey = hasKey(idempotencyKey);
        try {
            if (useKey) {
                if (sysRequestHistoryService.shouldSkipProcessing(idempotencyKey)) {
                    return ResponseEntity.status(HttpStatus.ALREADY_REPORTED).build();
                }
                sysRequestHistoryService.checkAndInsertIdempotency(idempotencyKey, request, "create");
            }
            SysRequestHistory saved = sysRequestHistoryService.createSysRequestHistory(request);
            if (useKey && saved.getId() != null) {
                sysRequestHistoryService.markHistorySuccess(idempotencyKey, saved.getId());
            }
            return ResponseEntity.status(HttpStatus.CREATED).body(saved);
        } catch (Exception ex) {
            if (useKey) {
                sysRequestHistoryService.markHistoryFailure(idempotencyKey, ex.getMessage());
            }
            LOG.log(Level.SEVERE, "Create request history failed", ex);
            return ResponseEntity.status(resolveStatus(ex)).build();
        }
    }

    @PutMapping("/{historyId}")
    @Operation(summary = "更新进度记录")
    public ResponseEntity<SysRequestHistory> update(@PathVariable Long historyId,
                                                    @RequestBody SysRequestHistory request,
                                                    @RequestHeader(value = "Idempotency-Key", required = false)
                                                    String idempotencyKey) {
        boolean useKey = hasKey(idempotencyKey);
        try {
            request.setId(historyId);
            if (useKey) {
                sysRequestHistoryService.checkAndInsertIdempotency(idempotencyKey, request, "update");
            }
            SysRequestHistory updated = sysRequestHistoryService.updateSysRequestHistory(request);
            if (useKey && updated.getId() != null) {
                sysRequestHistoryService.markHistorySuccess(idempotencyKey, updated.getId());
            }
            return ResponseEntity.ok(updated);
        } catch (Exception ex) {
            if (useKey) {
                sysRequestHistoryService.markHistoryFailure(idempotencyKey, ex.getMessage());
            }
            LOG.log(Level.SEVERE, "Update request history failed", ex);
            return ResponseEntity.status(resolveStatus(ex)).build();
        }
    }

    @DeleteMapping("/{historyId}")
    @Operation(summary = "删除进度记录")
    public ResponseEntity<Void> delete(@PathVariable Long historyId) {
        try {
            sysRequestHistoryService.deleteSysRequestHistory(historyId);
            return ResponseEntity.noContent().build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Delete request history failed", ex);
            return ResponseEntity.status(resolveStatus(ex)).build();
        }
    }

    @GetMapping("/{historyId}")
    @Operation(summary = "查询进度详情")
    public ResponseEntity<SysRequestHistory> get(@PathVariable Long historyId) {
        try {
            SysRequestHistory history = sysRequestHistoryService.findById(historyId);
            return history == null ? ResponseEntity.notFound().build() : ResponseEntity.ok(history);
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Get request history failed", ex);
            return ResponseEntity.status(resolveStatus(ex)).build();
        }
    }

    @GetMapping
    @Operation(summary = "查询全部进度记录")
    public ResponseEntity<List<SysRequestHistory>> list() {
        try {
            return ResponseEntity.ok(sysRequestHistoryService.findAll());
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "List request histories failed", ex);
            return ResponseEntity.status(resolveStatus(ex)).build();
        }
    }

    @GetMapping("/status")
    @Operation(summary = "按业务状态分页查询进度")
    public ResponseEntity<List<SysRequestHistory>> listByStatus(@RequestParam String status,
                                                                @RequestParam(defaultValue = "1") int page,
                                                                @RequestParam(defaultValue = "20") int size) {
        try {
            return ResponseEntity.ok(sysRequestHistoryService.findByBusinessStatus(status, page, size));
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "List request histories by status failed", ex);
            return ResponseEntity.status(resolveStatus(ex)).build();
        }
    }

    @GetMapping("/idempotency/{key}")
    @Operation(summary = "根据幂等键查询进度")
    public ResponseEntity<SysRequestHistory> getByIdempotencyKey(@PathVariable String key) {
        try {
            Optional<SysRequestHistory> history = sysRequestHistoryService.findByIdempotencyKey(key);
            return history.map(ResponseEntity::ok).orElseGet(() -> ResponseEntity.notFound().build());
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Get request history by idempotency key failed", ex);
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
