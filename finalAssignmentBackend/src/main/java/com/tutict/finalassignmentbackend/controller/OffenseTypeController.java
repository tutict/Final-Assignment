package com.tutict.finalassignmentbackend.controller;

import com.tutict.finalassignmentbackend.entity.OffenseTypeDict;
import com.tutict.finalassignmentbackend.service.OffenseTypeDictService;
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

    private boolean hasKey(String value) {
        return value != null && !value.isBlank();
    }

    private HttpStatus resolveStatus(Exception ex) {
        return (ex instanceof IllegalArgumentException || ex instanceof IllegalStateException)
                ? HttpStatus.BAD_REQUEST
                : HttpStatus.INTERNAL_SERVER_ERROR;
    }
}
