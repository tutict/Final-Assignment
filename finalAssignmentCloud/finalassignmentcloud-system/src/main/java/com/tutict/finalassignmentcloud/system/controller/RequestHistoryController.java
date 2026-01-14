package com.tutict.finalassignmentcloud.system.controller;

import com.tutict.finalassignmentcloud.entity.SysRequestHistory;
import com.tutict.finalassignmentcloud.system.service.SysRequestHistoryService;
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
@RequestMapping("/api/system/requests")
@Tag(name = "Request History", description = "请求历史记录接口")
@SecurityRequirement(name = "bearerAuth")
@RolesAllowed({"SUPER_ADMIN", "ADMIN"})
public class RequestHistoryController {

    private static final Logger LOG = Logger.getLogger(RequestHistoryController.class.getName());

    private final SysRequestHistoryService sysRequestHistoryService;

    public RequestHistoryController(SysRequestHistoryService sysRequestHistoryService) {
        this.sysRequestHistoryService = sysRequestHistoryService;
    }

    @PostMapping
    @Operation(summary = "创建请求历史记录")
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
    @Operation(summary = "更新请求历史记录")
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
    @Operation(summary = "删除请求历史记录")
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
    @Operation(summary = "查询请求历史记录详情")
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
    @Operation(summary = "查询全部请求历史记录")
    public ResponseEntity<List<SysRequestHistory>> list() {
        try {
            return ResponseEntity.ok(sysRequestHistoryService.findAll());
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "List request histories failed", ex);
            return ResponseEntity.status(resolveStatus(ex)).build();
        }
    }

    @GetMapping("/status")
    @Operation(summary = "按业务状态分页查询请求历史记录")
    public ResponseEntity<List<SysRequestHistory>> listByStatus(@RequestParam String status,
                                                                @RequestParam(defaultValue = "1") int page,
                                                                @RequestParam(defaultValue = "20") int size) {
        return ResponseEntity.ok(sysRequestHistoryService.findByBusinessStatus(status, page, size));
    }

    @GetMapping("/idempotency/{key}")
    @Operation(summary = "根据幂等键查询请求历史记录")
    public ResponseEntity<SysRequestHistory> getByIdempotencyKey(@PathVariable String key) {
        Optional<SysRequestHistory> history = sysRequestHistoryService.findByIdempotencyKey(key);
        return history.map(ResponseEntity::ok).orElseGet(() -> ResponseEntity.notFound().build());
    }

    @GetMapping("/search/idempotency")
    @Operation(summary = "Search request history by idempotency key")
    public ResponseEntity<List<SysRequestHistory>> searchByIdempotency(@RequestParam String key,
                                                                       @RequestParam(defaultValue = "1") int page,
                                                                       @RequestParam(defaultValue = "20") int size) {
        return ResponseEntity.ok(sysRequestHistoryService.searchByIdempotencyKey(key, page, size));
    }

    @GetMapping("/search/method")
    @Operation(summary = "Search request history by request method")
    public ResponseEntity<List<SysRequestHistory>> searchByRequestMethod(@RequestParam String requestMethod,
                                                                         @RequestParam(defaultValue = "1") int page,
                                                                         @RequestParam(defaultValue = "20") int size) {
        return ResponseEntity.ok(sysRequestHistoryService.searchByRequestMethod(requestMethod, page, size));
    }

    @GetMapping("/search/url")
    @Operation(summary = "Search request history by request URL prefix")
    public ResponseEntity<List<SysRequestHistory>> searchByRequestUrl(@RequestParam String requestUrl,
                                                                      @RequestParam(defaultValue = "1") int page,
                                                                      @RequestParam(defaultValue = "20") int size) {
        return ResponseEntity.ok(sysRequestHistoryService.searchByRequestUrlPrefix(requestUrl, page, size));
    }

    @GetMapping("/search/business-type")
    @Operation(summary = "Search request history by business type")
    public ResponseEntity<List<SysRequestHistory>> searchByBusinessType(@RequestParam String businessType,
                                                                        @RequestParam(defaultValue = "1") int page,
                                                                        @RequestParam(defaultValue = "20") int size) {
        return ResponseEntity.ok(sysRequestHistoryService.searchByBusinessType(businessType, page, size));
    }

    @GetMapping("/search/business-id")
    @Operation(summary = "Search request history by business id")
    public ResponseEntity<List<SysRequestHistory>> searchByBusinessId(@RequestParam Long businessId,
                                                                      @RequestParam(defaultValue = "1") int page,
                                                                      @RequestParam(defaultValue = "20") int size) {
        return ResponseEntity.ok(sysRequestHistoryService.findByBusinessId(businessId, page, size));
    }

    @GetMapping("/search/status")
    @Operation(summary = "Search request history by business status")
    public ResponseEntity<List<SysRequestHistory>> searchByBusinessStatus(@RequestParam String status,
                                                                          @RequestParam(defaultValue = "1") int page,
                                                                          @RequestParam(defaultValue = "20") int size) {
        return ResponseEntity.ok(sysRequestHistoryService.findByBusinessStatus(status, page, size));
    }

    @GetMapping("/search/user")
    @Operation(summary = "Search request history by user id")
    public ResponseEntity<List<SysRequestHistory>> searchByUser(@RequestParam Long userId,
                                                                @RequestParam(defaultValue = "1") int page,
                                                                @RequestParam(defaultValue = "20") int size) {
        return ResponseEntity.ok(sysRequestHistoryService.findByUserId(userId, page, size));
    }

    @GetMapping("/search/ip")
    @Operation(summary = "Search request history by request IP")
    public ResponseEntity<List<SysRequestHistory>> searchByRequestIp(@RequestParam String requestIp,
                                                                     @RequestParam(defaultValue = "1") int page,
                                                                     @RequestParam(defaultValue = "20") int size) {
        return ResponseEntity.ok(sysRequestHistoryService.searchByRequestIp(requestIp, page, size));
    }

    @GetMapping("/search/time-range")
    @Operation(summary = "Search request history by created time range")
    public ResponseEntity<List<SysRequestHistory>> searchByCreatedTimeRange(@RequestParam String startTime,
                                                                            @RequestParam String endTime,
                                                                            @RequestParam(defaultValue = "1") int page,
                                                                            @RequestParam(defaultValue = "20") int size) {
        return ResponseEntity.ok(sysRequestHistoryService.searchByCreatedAtRange(startTime, endTime, page, size));
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
