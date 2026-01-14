package com.tutict.finalassignmentcloud.traffic.controller;

import com.tutict.finalassignmentcloud.entity.OffenseTypeDict;
import com.tutict.finalassignmentcloud.traffic.service.OffenseTypeDictService;
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
@RequestMapping("/api/offense-types")
@Tag(name = "Offense Type Dictionary", description = "违法类型字典管理接口")
@SecurityRequirement(name = "bearerAuth")
@RolesAllowed({"SUPER_ADMIN", "ADMIN", "TRAFFIC_POLICE"})
public class OffenseTypeController {

    private static final Logger LOG = Logger.getLogger(OffenseTypeController.class.getName());

    private final OffenseTypeDictService offenseTypeDictService;

    public OffenseTypeController(OffenseTypeDictService offenseTypeDictService) {
        this.offenseTypeDictService = offenseTypeDictService;
    }

    @PostMapping
    @Operation(summary = "创建违法类型")
    public ResponseEntity<OffenseTypeDict> create(@RequestBody OffenseTypeDict request,
                                                  @RequestHeader(value = "Idempotency-Key", required = false)
                                                  String idempotencyKey) {
        boolean useKey = hasKey(idempotencyKey);
        try {
            if (useKey) {
                if (offenseTypeDictService.shouldSkipProcessing(idempotencyKey)) {
                    return ResponseEntity.status(HttpStatus.ALREADY_REPORTED).build();
                }
                offenseTypeDictService.checkAndInsertIdempotency(idempotencyKey, request, "create");
            }
            OffenseTypeDict saved = offenseTypeDictService.createDict(request);
            if (useKey && saved.getTypeId() != null) {
                offenseTypeDictService.markHistorySuccess(idempotencyKey, saved.getTypeId());
            }
            return ResponseEntity.status(HttpStatus.CREATED).body(saved);
        } catch (Exception ex) {
            if (useKey) {
                offenseTypeDictService.markHistoryFailure(idempotencyKey, ex.getMessage());
            }
            LOG.log(Level.SEVERE, "Create offense type failed", ex);
            return ResponseEntity.status(resolveStatus(ex)).build();
        }
    }

    @PutMapping("/{typeId}")
    @Operation(summary = "更新违法类型")
    public ResponseEntity<OffenseTypeDict> update(@PathVariable Integer typeId,
                                                  @RequestBody OffenseTypeDict request,
                                                  @RequestHeader(value = "Idempotency-Key", required = false)
                                                  String idempotencyKey) {
        boolean useKey = hasKey(idempotencyKey);
        try {
            request.setTypeId(typeId);
            if (useKey) {
                offenseTypeDictService.checkAndInsertIdempotency(idempotencyKey, request, "update");
            }
            OffenseTypeDict updated = offenseTypeDictService.updateDict(request);
            if (useKey && updated.getTypeId() != null) {
                offenseTypeDictService.markHistorySuccess(idempotencyKey, updated.getTypeId());
            }
            return ResponseEntity.ok(updated);
        } catch (Exception ex) {
            if (useKey) {
                offenseTypeDictService.markHistoryFailure(idempotencyKey, ex.getMessage());
            }
            LOG.log(Level.SEVERE, "Update offense type failed", ex);
            return ResponseEntity.status(resolveStatus(ex)).build();
        }
    }

    @DeleteMapping("/{typeId}")
    @Operation(summary = "删除违法类型")
    public ResponseEntity<Void> delete(@PathVariable Integer typeId) {
        try {
            offenseTypeDictService.deleteDict(typeId);
            return ResponseEntity.noContent().build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Delete offense type failed", ex);
            return ResponseEntity.status(resolveStatus(ex)).build();
        }
    }

    @GetMapping("/{typeId}")
    @Operation(summary = "查询违法类型详情")
    public ResponseEntity<OffenseTypeDict> get(@PathVariable Integer typeId) {
        try {
            OffenseTypeDict dict = offenseTypeDictService.findById(typeId);
            return dict == null ? ResponseEntity.notFound().build() : ResponseEntity.ok(dict);
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Get offense type failed", ex);
            return ResponseEntity.status(resolveStatus(ex)).build();
        }
    }

    @GetMapping
    @Operation(summary = "查询全部违法类型")
    public ResponseEntity<List<OffenseTypeDict>> list() {
        try {
            return ResponseEntity.ok(offenseTypeDictService.findAll());
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "List offense types failed", ex);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    @GetMapping("/search/code/prefix")
    @Operation(summary = "Search offense types by code prefix")
    public ResponseEntity<List<OffenseTypeDict>> searchByCodePrefix(@RequestParam String offenseCode,
                                                                     @RequestParam(defaultValue = "1") int page,
                                                                     @RequestParam(defaultValue = "20") int size) {
        return ResponseEntity.ok(offenseTypeDictService.searchByOffenseCodePrefix(offenseCode, page, size));
    }

    @GetMapping("/search/code/fuzzy")
    @Operation(summary = "Search offense types by code fuzzy")
    public ResponseEntity<List<OffenseTypeDict>> searchByCodeFuzzy(@RequestParam String offenseCode,
                                                                    @RequestParam(defaultValue = "1") int page,
                                                                    @RequestParam(defaultValue = "20") int size) {
        return ResponseEntity.ok(offenseTypeDictService.searchByOffenseCodeFuzzy(offenseCode, page, size));
    }

    @GetMapping("/search/name/prefix")
    @Operation(summary = "Search offense types by name prefix")
    public ResponseEntity<List<OffenseTypeDict>> searchByNamePrefix(@RequestParam String offenseName,
                                                                     @RequestParam(defaultValue = "1") int page,
                                                                     @RequestParam(defaultValue = "20") int size) {
        return ResponseEntity.ok(offenseTypeDictService.searchByOffenseNamePrefix(offenseName, page, size));
    }

    @GetMapping("/search/name/fuzzy")
    @Operation(summary = "Search offense types by name fuzzy")
    public ResponseEntity<List<OffenseTypeDict>> searchByNameFuzzy(@RequestParam String offenseName,
                                                                    @RequestParam(defaultValue = "1") int page,
                                                                    @RequestParam(defaultValue = "20") int size) {
        return ResponseEntity.ok(offenseTypeDictService.searchByOffenseNameFuzzy(offenseName, page, size));
    }

    @GetMapping("/search/category")
    @Operation(summary = "Search offense types by category")
    public ResponseEntity<List<OffenseTypeDict>> searchByCategory(@RequestParam String category,
                                                                   @RequestParam(defaultValue = "1") int page,
                                                                   @RequestParam(defaultValue = "20") int size) {
        return ResponseEntity.ok(offenseTypeDictService.searchByCategory(category, page, size));
    }

    @GetMapping("/search/severity")
    @Operation(summary = "Search offense types by severity level")
    public ResponseEntity<List<OffenseTypeDict>> searchBySeverity(@RequestParam String severityLevel,
                                                                   @RequestParam(defaultValue = "1") int page,
                                                                   @RequestParam(defaultValue = "20") int size) {
        return ResponseEntity.ok(offenseTypeDictService.searchBySeverityLevel(severityLevel, page, size));
    }

    @GetMapping("/search/status")
    @Operation(summary = "Search offense types by status")
    public ResponseEntity<List<OffenseTypeDict>> searchByStatus(@RequestParam String status,
                                                                 @RequestParam(defaultValue = "1") int page,
                                                                 @RequestParam(defaultValue = "20") int size) {
        return ResponseEntity.ok(offenseTypeDictService.searchByStatus(status, page, size));
    }

    @GetMapping("/search/fine-range")
    @Operation(summary = "Search offense types by standard fine amount range")
    public ResponseEntity<List<OffenseTypeDict>> searchByFineRange(@RequestParam double minAmount,
                                                                    @RequestParam double maxAmount,
                                                                    @RequestParam(defaultValue = "1") int page,
                                                                    @RequestParam(defaultValue = "20") int size) {
        return ResponseEntity.ok(offenseTypeDictService.searchByStandardFineAmountRange(minAmount, maxAmount, page, size));
    }

    @GetMapping("/search/points-range")
    @Operation(summary = "Search offense types by deducted points range")
    public ResponseEntity<List<OffenseTypeDict>> searchByPointsRange(@RequestParam int minPoints,
                                                                      @RequestParam int maxPoints,
                                                                      @RequestParam(defaultValue = "1") int page,
                                                                      @RequestParam(defaultValue = "20") int size) {
        return ResponseEntity.ok(offenseTypeDictService.searchByDeductedPointsRange(minPoints, maxPoints, page, size));
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

