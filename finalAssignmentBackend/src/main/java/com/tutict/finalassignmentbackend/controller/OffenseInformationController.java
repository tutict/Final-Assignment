package com.tutict.finalassignmentbackend.controller;

import com.tutict.finalassignmentbackend.entity.OffenseRecord;
import com.tutict.finalassignmentbackend.service.OffenseRecordService;
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
@RequestMapping("/api/offenses")
@Tag(name = "Offense Management", description = "交通违法记录管理接口")
@SecurityRequirement(name = "bearerAuth")
@RolesAllowed({"SUPER_ADMIN", "ADMIN", "TRAFFIC_POLICE", "APPEAL_REVIEWER"})
public class OffenseInformationController {

    private static final Logger LOG = Logger.getLogger(OffenseInformationController.class.getName());

    private final OffenseRecordService offenseRecordService;

    public OffenseInformationController(OffenseRecordService offenseRecordService) {
        this.offenseRecordService = offenseRecordService;
    }

    @PostMapping
    @Operation(summary = "创建违法记录")
    public ResponseEntity<OffenseRecord> create(@RequestBody OffenseRecord request,
                                                @RequestHeader(value = "Idempotency-Key", required = false)
                                                String idempotencyKey) {
        boolean useKey = hasKey(idempotencyKey);
        try {
            if (useKey) {
                if (offenseRecordService.shouldSkipProcessing(idempotencyKey)) {
                    return ResponseEntity.status(HttpStatus.ALREADY_REPORTED).build();
                }
                offenseRecordService.checkAndInsertIdempotency(idempotencyKey, request, "create");
            }
            OffenseRecord saved = offenseRecordService.createOffenseRecord(request);
            if (useKey && saved.getOffenseId() != null) {
                offenseRecordService.markHistorySuccess(idempotencyKey, saved.getOffenseId());
            }
            return ResponseEntity.status(HttpStatus.CREATED).body(saved);
        } catch (Exception ex) {
            if (useKey) {
                offenseRecordService.markHistoryFailure(idempotencyKey, ex.getMessage());
            }
            LOG.log(Level.SEVERE, "Create offense failed", ex);
            return ResponseEntity.status(resolveStatus(ex)).build();
        }
    }

    @PutMapping("/{offenseId}")
    @Operation(summary = "更新违法记录")
    public ResponseEntity<OffenseRecord> update(@PathVariable Long offenseId,
                                                @RequestBody OffenseRecord request,
                                                @RequestHeader(value = "Idempotency-Key", required = false)
                                                String idempotencyKey) {
        boolean useKey = hasKey(idempotencyKey);
        try {
            request.setOffenseId(offenseId);
            if (useKey) {
                offenseRecordService.checkAndInsertIdempotency(idempotencyKey, request, "update");
            }
            OffenseRecord updated = offenseRecordService.updateOffenseRecord(request);
            if (useKey && updated.getOffenseId() != null) {
                offenseRecordService.markHistorySuccess(idempotencyKey, updated.getOffenseId());
            }
            return ResponseEntity.ok(updated);
        } catch (Exception ex) {
            if (useKey) {
                offenseRecordService.markHistoryFailure(idempotencyKey, ex.getMessage());
            }
            LOG.log(Level.SEVERE, "Update offense failed", ex);
            return ResponseEntity.status(resolveStatus(ex)).build();
        }
    }

    @DeleteMapping("/{offenseId}")
    @Operation(summary = "删除违法记录")
    public ResponseEntity<Void> delete(@PathVariable Long offenseId) {
        try {
            offenseRecordService.deleteOffenseRecord(offenseId);
            return ResponseEntity.noContent().build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Delete offense failed", ex);
            return ResponseEntity.status(resolveStatus(ex)).build();
        }
    }

    @GetMapping("/{offenseId}")
    @Operation(summary = "查询违法详情")
    public ResponseEntity<OffenseRecord> get(@PathVariable Long offenseId) {
        try {
            OffenseRecord record = offenseRecordService.findById(offenseId);
            return record == null ? ResponseEntity.notFound().build() : ResponseEntity.ok(record);
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Get offense failed", ex);
            return ResponseEntity.status(resolveStatus(ex)).build();
        }
    }

    @GetMapping
    @Operation(summary = "查询全部违法记录")
    public ResponseEntity<List<OffenseRecord>> list() {
        try {
            return ResponseEntity.ok(offenseRecordService.findAll());
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "List offenses failed", ex);
            return ResponseEntity.status(resolveStatus(ex)).build();
        }
    }

    @GetMapping("/driver/{driverId}")
    @Operation(summary = "按驾驶证分页查询违法")
    public ResponseEntity<List<OffenseRecord>> byDriver(@PathVariable Long driverId,
                                                        @RequestParam(defaultValue = "1") int page,
                                                        @RequestParam(defaultValue = "20") int size) {
        try {
            return ResponseEntity.ok(offenseRecordService.findByDriverId(driverId, page, size));
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "List offenses by driver failed", ex);
            return ResponseEntity.status(resolveStatus(ex)).build();
        }
    }

    @GetMapping("/vehicle/{vehicleId}")
    @Operation(summary = "按车辆分页查询违法")
    public ResponseEntity<List<OffenseRecord>> byVehicle(@PathVariable Long vehicleId,
                                                         @RequestParam(defaultValue = "1") int page,
                                                         @RequestParam(defaultValue = "20") int size) {
        try {
            return ResponseEntity.ok(offenseRecordService.findByVehicleId(vehicleId, page, size));
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "List offenses by vehicle failed", ex);
            return ResponseEntity.status(resolveStatus(ex)).build();
        }
    }

    @GetMapping("/search/code")
    @Operation(summary = "按违法代码搜索")
    public ResponseEntity<List<OffenseRecord>> searchByCode(@RequestParam String offenseCode,
                                                            @RequestParam(defaultValue = "1") int page,
                                                            @RequestParam(defaultValue = "20") int size) {
        try {
            return ResponseEntity.ok(offenseRecordService.searchByOffenseCode(offenseCode, page, size));
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Search offense by code failed", ex);
            return ResponseEntity.status(resolveStatus(ex)).build();
        }
    }

    @GetMapping("/search/status")
    @Operation(summary = "按处理状态搜索")
    public ResponseEntity<List<OffenseRecord>> searchByStatus(@RequestParam String status,
                                                              @RequestParam(defaultValue = "1") int page,
                                                              @RequestParam(defaultValue = "20") int size) {
        try {
            return ResponseEntity.ok(offenseRecordService.searchByProcessStatus(status, page, size));
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Search offense by status failed", ex);
            return ResponseEntity.status(resolveStatus(ex)).build();
        }
    }

    @GetMapping("/search/time-range")
    @Operation(summary = "按违法时间范围搜索")
    public ResponseEntity<List<OffenseRecord>> searchByTimeRange(@RequestParam String startTime,
                                                                 @RequestParam String endTime,
                                                                 @RequestParam(defaultValue = "1") int page,
                                                                 @RequestParam(defaultValue = "20") int size) {
        try {
            return ResponseEntity.ok(offenseRecordService.searchByOffenseTimeRange(startTime, endTime, page, size));
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Search offense by time range failed", ex);
            return ResponseEntity.status(resolveStatus(ex)).build();
        }
    }

    @GetMapping("/search/number")
    @Operation(summary = "按违法编号搜索")
    public ResponseEntity<List<OffenseRecord>> searchByNumber(@RequestParam String offenseNumber,
                                                              @RequestParam(defaultValue = "1") int page,
                                                              @RequestParam(defaultValue = "20") int size) {
        try {
            return ResponseEntity.ok(offenseRecordService.searchByOffenseNumber(offenseNumber, page, size));
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Search offense by number failed", ex);
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
