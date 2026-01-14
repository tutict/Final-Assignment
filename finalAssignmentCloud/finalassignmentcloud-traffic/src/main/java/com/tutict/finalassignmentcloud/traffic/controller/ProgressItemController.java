package com.tutict.finalassignmentcloud.traffic.controller;

import com.tutict.finalassignmentcloud.entity.SysRequestHistory;
import com.tutict.finalassignmentcloud.traffic.client.SystemRequestHistoryClient;
import feign.FeignException;
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
@RequestMapping("/api/progress")
@Tag(name = "Progress Tracker", description = "幂等请求进度跟踪接口")
@SecurityRequirement(name = "bearerAuth")
@RolesAllowed({"SUPER_ADMIN", "ADMIN"})
public class ProgressItemController {

    private static final Logger LOG = Logger.getLogger(ProgressItemController.class.getName());

    private final SystemRequestHistoryClient requestHistoryClient;

    public ProgressItemController(SystemRequestHistoryClient requestHistoryClient) {
        this.requestHistoryClient = requestHistoryClient;
    }

    @PostMapping
    @Operation(summary = "创建进度记录")
    public ResponseEntity<SysRequestHistory> create(@RequestBody SysRequestHistory request,
                                                    @RequestHeader(value = "Idempotency-Key", required = false)
                                                    String idempotencyKey) {
        try {
            SysRequestHistory saved = requestHistoryClient.create(request, idempotencyKey);
            if (saved == null) {
                return ResponseEntity.status(HttpStatus.ALREADY_REPORTED).build();
            }
            return ResponseEntity.status(HttpStatus.CREATED).body(saved);
        } catch (FeignException ex) {
            return ResponseEntity.status(resolveStatus(ex)).build();
        } catch (Exception ex) {
            LOG.log(Level.SEVERE, "Create request history failed", ex);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    @PutMapping("/{historyId}")
    @Operation(summary = "更新进度记录")
    public ResponseEntity<SysRequestHistory> update(@PathVariable Long historyId,
                                                    @RequestBody SysRequestHistory request,
                                                    @RequestHeader(value = "Idempotency-Key", required = false)
                                                    String idempotencyKey) {
        try {
            SysRequestHistory updated = requestHistoryClient.update(historyId, request, idempotencyKey);
            if (updated == null) {
                return ResponseEntity.status(HttpStatus.ALREADY_REPORTED).build();
            }
            return ResponseEntity.ok(updated);
        } catch (FeignException ex) {
            return ResponseEntity.status(resolveStatus(ex)).build();
        } catch (Exception ex) {
            LOG.log(Level.SEVERE, "Update request history failed", ex);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    @DeleteMapping("/{historyId}")
    @Operation(summary = "删除进度记录")
    public ResponseEntity<Void> delete(@PathVariable Long historyId) {
        try {
            requestHistoryClient.delete(historyId);
            return ResponseEntity.noContent().build();
        } catch (FeignException ex) {
            return ResponseEntity.status(resolveStatus(ex)).build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Delete request history failed", ex);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    @GetMapping("/{historyId}")
    @Operation(summary = "查询进度记录")
    public ResponseEntity<SysRequestHistory> get(@PathVariable Long historyId) {
        try {
            SysRequestHistory history = requestHistoryClient.get(historyId);
            return history == null ? ResponseEntity.notFound().build() : ResponseEntity.ok(history);
        } catch (FeignException.NotFound ex) {
            return ResponseEntity.notFound().build();
        } catch (FeignException ex) {
            return ResponseEntity.status(resolveStatus(ex)).build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Get request history failed", ex);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    @GetMapping
    @Operation(summary = "查询全部进度记录")
    public ResponseEntity<List<SysRequestHistory>> list() {
        try {
            return ResponseEntity.ok(requestHistoryClient.list());
        } catch (FeignException ex) {
            return ResponseEntity.status(resolveStatus(ex)).build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "List request histories failed", ex);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    @GetMapping("/status")
    @Operation(summary = "按业务状态分页查询进度记录")
    public ResponseEntity<List<SysRequestHistory>> listByStatus(@RequestParam String status,
                                                                @RequestParam(defaultValue = "1") int page,
                                                                @RequestParam(defaultValue = "20") int size) {
        try {
            return ResponseEntity.ok(requestHistoryClient.listByStatus(status, page, size));
        } catch (FeignException ex) {
            return ResponseEntity.status(resolveStatus(ex)).build();
        }
    }

    @GetMapping("/idempotency/{key}")
    @Operation(summary = "根据幂等键查询进度记录")
    public ResponseEntity<SysRequestHistory> getByIdempotencyKey(@PathVariable String key) {
        try {
            SysRequestHistory history = requestHistoryClient.getByIdempotencyKey(key);
            return history == null ? ResponseEntity.notFound().build() : ResponseEntity.ok(history);
        } catch (FeignException.NotFound ex) {
            return ResponseEntity.notFound().build();
        } catch (FeignException ex) {
            return ResponseEntity.status(resolveStatus(ex)).build();
        }
    }

    private HttpStatus resolveStatus(FeignException ex) {
        int status = ex.status();
        if (status == 400) {
            return HttpStatus.BAD_REQUEST;
        }
        if (status == 404) {
            return HttpStatus.NOT_FOUND;
        }
        if (status == 409) {
            return HttpStatus.CONFLICT;
        }
        if (status == 422) {
            return HttpStatus.UNPROCESSABLE_ENTITY;
        }
        return HttpStatus.INTERNAL_SERVER_ERROR;
    }
}
