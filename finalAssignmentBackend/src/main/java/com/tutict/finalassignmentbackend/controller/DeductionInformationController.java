package com.tutict.finalassignmentbackend.controller;

import com.tutict.finalassignmentbackend.entity.DeductionRecord;
import com.tutict.finalassignmentbackend.service.DeductionRecordService;
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
@RequestMapping("/api/deductions")
@Tag(name = "Deduction Management", description = "驾照扣分记录管理接口")
@SecurityRequirement(name = "bearerAuth")
@RolesAllowed({"SUPER_ADMIN", "ADMIN", "TRAFFIC_POLICE"})
public class DeductionInformationController {

    private static final Logger LOG = Logger.getLogger(DeductionInformationController.class.getName());

    private final DeductionRecordService deductionRecordService;

    public DeductionInformationController(DeductionRecordService deductionRecordService) {
        this.deductionRecordService = deductionRecordService;
    }

    @PostMapping
    @Operation(summary = "创建扣分记录")
    public ResponseEntity<DeductionRecord> create(@RequestBody DeductionRecord request,
                                                  @RequestHeader(value = "Idempotency-Key", required = false)
                                                  String idempotencyKey) {
        boolean useKey = hasKey(idempotencyKey);
        try {
            if (useKey) {
                if (deductionRecordService.shouldSkipProcessing(idempotencyKey)) {
                    return ResponseEntity.status(HttpStatus.ALREADY_REPORTED).build();
                }
                deductionRecordService.checkAndInsertIdempotency(idempotencyKey, request, "create");
            }
            DeductionRecord saved = deductionRecordService.createDeductionRecord(request);
            if (useKey && saved.getDeductionId() != null) {
                deductionRecordService.markHistorySuccess(idempotencyKey, saved.getDeductionId());
            }
            return ResponseEntity.status(HttpStatus.CREATED).body(saved);
        } catch (Exception ex) {
            if (useKey) {
                deductionRecordService.markHistoryFailure(idempotencyKey, ex.getMessage());
            }
            LOG.log(Level.SEVERE, "Create deduction failed", ex);
            return ResponseEntity.status(resolveStatus(ex)).build();
        }
    }

    @PutMapping("/{deductionId}")
    @Operation(summary = "更新扣分记录")
    public ResponseEntity<DeductionRecord> update(@PathVariable Long deductionId,
                                                  @RequestBody DeductionRecord request,
                                                  @RequestHeader(value = "Idempotency-Key", required = false)
                                                  String idempotencyKey) {
        boolean useKey = hasKey(idempotencyKey);
        try {
            request.setDeductionId(deductionId);
            if (useKey) {
                deductionRecordService.checkAndInsertIdempotency(idempotencyKey, request, "update");
            }
            DeductionRecord updated = deductionRecordService.updateDeductionRecord(request);
            if (useKey && updated.getDeductionId() != null) {
                deductionRecordService.markHistorySuccess(idempotencyKey, updated.getDeductionId());
            }
            return ResponseEntity.ok(updated);
        } catch (Exception ex) {
            if (useKey) {
                deductionRecordService.markHistoryFailure(idempotencyKey, ex.getMessage());
            }
            LOG.log(Level.SEVERE, "Update deduction failed", ex);
            return ResponseEntity.status(resolveStatus(ex)).build();
        }
    }

    @DeleteMapping("/{deductionId}")
    @Operation(summary = "删除扣分记录")
    public ResponseEntity<Void> delete(@PathVariable Long deductionId) {
        try {
            deductionRecordService.deleteDeductionRecord(deductionId);
            return ResponseEntity.noContent().build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Delete deduction failed", ex);
            return ResponseEntity.status(resolveStatus(ex)).build();
        }
    }

    @GetMapping("/{deductionId}")
    @Operation(summary = "查询扣分详情")
    public ResponseEntity<DeductionRecord> get(@PathVariable Long deductionId) {
        try {
            DeductionRecord record = deductionRecordService.findById(deductionId);
            return record == null ? ResponseEntity.notFound().build() : ResponseEntity.ok(record);
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Get deduction failed", ex);
            return ResponseEntity.status(resolveStatus(ex)).build();
        }
    }

    @GetMapping
    @Operation(summary = "查询全部扣分记录")
    public ResponseEntity<List<DeductionRecord>> list() {
        try {
            return ResponseEntity.ok(deductionRecordService.findAll());
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "List deductions failed", ex);
            return ResponseEntity.status(resolveStatus(ex)).build();
        }
    }

    @GetMapping("/driver/{driverId}")
    @Operation(summary = "按驾驶证分页查询扣分")
    public ResponseEntity<List<DeductionRecord>> byDriver(@PathVariable Long driverId,
                                                          @RequestParam(defaultValue = "1") int page,
                                                          @RequestParam(defaultValue = "20") int size) {
        try {
            return ResponseEntity.ok(deductionRecordService.findByDriverId(driverId, page, size));
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "List deductions by driver failed", ex);
            return ResponseEntity.status(resolveStatus(ex)).build();
        }
    }

    @GetMapping("/offense/{offenseId}")
    @Operation(summary = "按违法记录分页查询扣分")
    public ResponseEntity<List<DeductionRecord>> byOffense(@PathVariable Long offenseId,
                                                           @RequestParam(defaultValue = "1") int page,
                                                           @RequestParam(defaultValue = "20") int size) {
        try {
            return ResponseEntity.ok(deductionRecordService.findByOffenseId(offenseId, page, size));
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "List deductions by offense failed", ex);
            return ResponseEntity.status(resolveStatus(ex)).build();
        }
    }

    @GetMapping("/search/handler")
    @Operation(summary = "按经办人模糊搜索")
    public ResponseEntity<List<DeductionRecord>> searchByHandler(@RequestParam String handler,
                                                                 @RequestParam(defaultValue = "prefix") String mode,
                                                                 @RequestParam(defaultValue = "1") int page,
                                                                 @RequestParam(defaultValue = "20") int size) {
        try {
            List<DeductionRecord> result = "fuzzy".equalsIgnoreCase(mode)
                    ? deductionRecordService.searchByHandlerFuzzy(handler, page, size)
                    : deductionRecordService.searchByHandlerPrefix(handler, page, size);
            return ResponseEntity.ok(result);
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Search deduction by handler failed", ex);
            return ResponseEntity.status(resolveStatus(ex)).build();
        }
    }

    @GetMapping("/search/status")
    @Operation(summary = "按处理状态分页查询")
    public ResponseEntity<List<DeductionRecord>> searchByStatus(@RequestParam String status,
                                                                @RequestParam(defaultValue = "1") int page,
                                                                @RequestParam(defaultValue = "20") int size) {
        try {
            return ResponseEntity.ok(deductionRecordService.searchByStatus(status, page, size));
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Search deduction by status failed", ex);
            return ResponseEntity.status(resolveStatus(ex)).build();
        }
    }

    @GetMapping("/search/time-range")
    @Operation(summary = "按时间范围分页查询")
    public ResponseEntity<List<DeductionRecord>> searchByTimeRange(@RequestParam String startTime,
                                                                   @RequestParam String endTime,
                                                                   @RequestParam(defaultValue = "1") int page,
                                                                   @RequestParam(defaultValue = "20") int size) {
        try {
            return ResponseEntity.ok(deductionRecordService.searchByDeductionTimeRange(startTime, endTime, page, size));
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Search deduction by time range failed", ex);
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
