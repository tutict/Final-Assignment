package com.tutict.finalassignmentbackend.controller;

import com.tutict.finalassignmentbackend.entity.FineRecord;
import com.tutict.finalassignmentbackend.service.FineRecordService;
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
@RequestMapping("/api/fines")
@Tag(name = "Fine Management", description = "罚款信息管理接口")
@SecurityRequirement(name = "bearerAuth")
@RolesAllowed({"SUPER_ADMIN", "ADMIN", "TRAFFIC_POLICE", "FINANCE"})
public class FineInformationController {

    private static final Logger LOG = Logger.getLogger(FineInformationController.class.getName());

    private final FineRecordService fineRecordService;

    public FineInformationController(FineRecordService fineRecordService) {
        this.fineRecordService = fineRecordService;
    }

    @PostMapping
    @Operation(summary = "创建罚款记录")
    public ResponseEntity<FineRecord> create(@RequestBody FineRecord request,
                                             @RequestHeader(value = "Idempotency-Key", required = false)
                                             String idempotencyKey) {
        boolean useKey = hasKey(idempotencyKey);
        try {
            if (useKey) {
                if (fineRecordService.shouldSkipProcessing(idempotencyKey)) {
                    return ResponseEntity.status(HttpStatus.ALREADY_REPORTED).build();
                }
                fineRecordService.checkAndInsertIdempotency(idempotencyKey, request, "create");
            }
            FineRecord saved = fineRecordService.createFineRecord(request);
            if (useKey && saved.getFineId() != null) {
                fineRecordService.markHistorySuccess(idempotencyKey, saved.getFineId());
            }
            return ResponseEntity.status(HttpStatus.CREATED).body(saved);
        } catch (Exception ex) {
            if (useKey) {
                fineRecordService.markHistoryFailure(idempotencyKey, ex.getMessage());
            }
            LOG.log(Level.SEVERE, "Create fine failed", ex);
            return ResponseEntity.status(resolveStatus(ex)).build();
        }
    }

    @PutMapping("/{fineId}")
    @Operation(summary = "更新罚款记录")
    public ResponseEntity<FineRecord> update(@PathVariable Long fineId,
                                             @RequestBody FineRecord request,
                                             @RequestHeader(value = "Idempotency-Key", required = false)
                                             String idempotencyKey) {
        boolean useKey = hasKey(idempotencyKey);
        try {
            request.setFineId(fineId);
            if (useKey) {
                fineRecordService.checkAndInsertIdempotency(idempotencyKey, request, "update");
            }
            FineRecord updated = fineRecordService.updateFineRecord(request);
            if (useKey && updated.getFineId() != null) {
                fineRecordService.markHistorySuccess(idempotencyKey, updated.getFineId());
            }
            return ResponseEntity.ok(updated);
        } catch (Exception ex) {
            if (useKey) {
                fineRecordService.markHistoryFailure(idempotencyKey, ex.getMessage());
            }
            LOG.log(Level.SEVERE, "Update fine failed", ex);
            return ResponseEntity.status(resolveStatus(ex)).build();
        }
    }

    @DeleteMapping("/{fineId}")
    @Operation(summary = "删除罚款记录")
    public ResponseEntity<Void> delete(@PathVariable Long fineId) {
        try {
            fineRecordService.deleteFineRecord(fineId);
            return ResponseEntity.noContent().build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Delete fine failed", ex);
            return ResponseEntity.status(resolveStatus(ex)).build();
        }
    }

    @GetMapping("/{fineId}")
    @Operation(summary = "查询罚款详情")
    public ResponseEntity<FineRecord> get(@PathVariable Long fineId) {
        try {
            FineRecord record = fineRecordService.findById(fineId);
            return record == null ? ResponseEntity.notFound().build() : ResponseEntity.ok(record);
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Get fine failed", ex);
            return ResponseEntity.status(resolveStatus(ex)).build();
        }
    }

    @GetMapping
    @Operation(summary = "查询全部罚款记录")
    public ResponseEntity<List<FineRecord>> list() {
        try {
            return ResponseEntity.ok(fineRecordService.findAll());
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "List fines failed", ex);
            return ResponseEntity.status(resolveStatus(ex)).build();
        }
    }

    @GetMapping("/offense/{offenseId}")
    @Operation(summary = "按违法记录分页查询罚款")
    public ResponseEntity<List<FineRecord>> byOffense(@PathVariable Long offenseId,
                                                      @RequestParam(defaultValue = "1") int page,
                                                      @RequestParam(defaultValue = "20") int size) {
        try {
            return ResponseEntity.ok(fineRecordService.findByOffenseId(offenseId, page, size));
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "List fines by offense failed", ex);
            return ResponseEntity.status(resolveStatus(ex)).build();
        }
    }

    @GetMapping("/search/handler")
    @Operation(summary = "按处理人搜索罚款记录")
    public ResponseEntity<List<FineRecord>> searchByHandler(@RequestParam String handler,
                                                            @RequestParam(defaultValue = "prefix") String mode,
                                                            @RequestParam(defaultValue = "1") int page,
                                                            @RequestParam(defaultValue = "20") int size) {
        try {
            List<FineRecord> result = "fuzzy".equalsIgnoreCase(mode)
                    ? fineRecordService.searchByHandlerFuzzy(handler, page, size)
                    : fineRecordService.searchByHandlerPrefix(handler, page, size);
            return ResponseEntity.ok(result);
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Search fine by handler failed", ex);
            return ResponseEntity.status(resolveStatus(ex)).build();
        }
    }

    @GetMapping("/search/status")
    @Operation(summary = "按支付状态搜索罚款")
    public ResponseEntity<List<FineRecord>> searchByPaymentStatus(@RequestParam String status,
                                                                  @RequestParam(defaultValue = "1") int page,
                                                                  @RequestParam(defaultValue = "20") int size) {
        try {
            return ResponseEntity.ok(fineRecordService.searchByPaymentStatus(status, page, size));
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Search fine by status failed", ex);
            return ResponseEntity.status(resolveStatus(ex)).build();
        }
    }

    @GetMapping("/search/date-range")
    @Operation(summary = "按开具日期搜索罚款")
    public ResponseEntity<List<FineRecord>> searchByDateRange(@RequestParam String startDate,
                                                              @RequestParam String endDate,
                                                              @RequestParam(defaultValue = "1") int page,
                                                              @RequestParam(defaultValue = "20") int size) {
        try {
            return ResponseEntity.ok(fineRecordService.searchByFineDateRange(startDate, endDate, page, size));
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Search fine by date range failed", ex);
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
