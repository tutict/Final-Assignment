package com.tutict.finalassignmentcloud.system.controller;

import com.tutict.finalassignmentcloud.entity.SysBackupRestore;
import com.tutict.finalassignmentcloud.system.service.SysBackupRestoreService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.annotation.security.RolesAllowed;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/system/backup")
@Tag(name = "Backup & Restore", description = "系统备份与还原管理接口")
@SecurityRequirement(name = "bearerAuth")
@RolesAllowed({"SUPER_ADMIN", "ADMIN"})
public class BackupRestoreController {

    private static final Logger LOG = Logger.getLogger(BackupRestoreController.class.getName());

    private final SysBackupRestoreService backupRestoreService;

    public BackupRestoreController(SysBackupRestoreService backupRestoreService) {
        this.backupRestoreService = backupRestoreService;
    }

    @PostMapping
    @Operation(summary = "创建备份/还原任务")
    public ResponseEntity<SysBackupRestore> create(@RequestBody SysBackupRestore request,
                                                   @RequestHeader(value = "Idempotency-Key", required = false)
                                                   String idempotencyKey) {
        boolean useKey = hasKey(idempotencyKey);
        try {
            if (useKey) {
                if (backupRestoreService.shouldSkipProcessing(idempotencyKey)) {
                    return ResponseEntity.status(HttpStatus.ALREADY_REPORTED).build();
                }
                backupRestoreService.checkAndInsertIdempotency(idempotencyKey, request, "create");
            }
            SysBackupRestore saved = backupRestoreService.createSysBackupRestore(request);
            if (useKey && saved.getBackupId() != null) {
                backupRestoreService.markHistorySuccess(idempotencyKey, saved.getBackupId());
            }
            return ResponseEntity.status(HttpStatus.CREATED).body(saved);
        } catch (Exception ex) {
            if (useKey) {
                backupRestoreService.markHistoryFailure(idempotencyKey, ex.getMessage());
            }
            LOG.log(Level.SEVERE, "Create backup task failed", ex);
            return ResponseEntity.status(resolveStatus(ex)).build();
        }
    }

    @PutMapping("/{backupId}")
    @Operation(summary = "更新备份/还原任务")
    public ResponseEntity<SysBackupRestore> update(@PathVariable Long backupId,
                                                   @RequestBody SysBackupRestore request,
                                                   @RequestHeader(value = "Idempotency-Key", required = false)
                                                   String idempotencyKey) {
        boolean useKey = hasKey(idempotencyKey);
        try {
            request.setBackupId(backupId);
            if (useKey) {
                backupRestoreService.checkAndInsertIdempotency(idempotencyKey, request, "update");
            }
            SysBackupRestore updated = backupRestoreService.updateSysBackupRestore(request);
            if (useKey && updated.getBackupId() != null) {
                backupRestoreService.markHistorySuccess(idempotencyKey, updated.getBackupId());
            }
            return ResponseEntity.ok(updated);
        } catch (Exception ex) {
            if (useKey) {
                backupRestoreService.markHistoryFailure(idempotencyKey, ex.getMessage());
            }
            LOG.log(Level.SEVERE, "Update backup task failed", ex);
            return ResponseEntity.status(resolveStatus(ex)).build();
        }
    }

    @DeleteMapping("/{backupId}")
    @Operation(summary = "删除备份/还原任务")
    public ResponseEntity<Void> delete(@PathVariable Long backupId) {
        try {
            backupRestoreService.deleteSysBackupRestore(backupId);
            return ResponseEntity.noContent().build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Delete backup task failed", ex);
            return ResponseEntity.status(resolveStatus(ex)).build();
        }
    }

    @GetMapping("/{backupId}")
    @Operation(summary = "查询备份/还原详情")
    public ResponseEntity<SysBackupRestore> get(@PathVariable Long backupId) {
        try {
            SysBackupRestore record = backupRestoreService.findById(backupId);
            return record == null ? ResponseEntity.notFound().build() : ResponseEntity.ok(record);
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Get backup task failed", ex);
            return ResponseEntity.status(resolveStatus(ex)).build();
        }
    }

    @GetMapping
    @Operation(summary = "查询备份/还原任务列表")
    public ResponseEntity<List<SysBackupRestore>> list(@RequestParam(value = "status", required = false) String status) {
        try {
            List<SysBackupRestore> all = backupRestoreService.findAll();
            if (status == null || status.isBlank()) {
                return ResponseEntity.ok(all);
            }
            List<SysBackupRestore> filtered = all.stream()
                    .filter(item -> status.equalsIgnoreCase(item.getStatus()))
                    .collect(Collectors.toList());
            return ResponseEntity.ok(filtered);
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "List backup tasks failed", ex);
            return ResponseEntity.status(resolveStatus(ex)).build();
        }
    }

    @GetMapping("/search/type")
    @Operation(summary = "Search backup tasks by type")
    public ResponseEntity<List<SysBackupRestore>> searchByType(@RequestParam String backupType,
                                                               @RequestParam(defaultValue = "1") int page,
                                                               @RequestParam(defaultValue = "20") int size) {
        return ResponseEntity.ok(backupRestoreService.searchByBackupType(backupType, page, size));
    }

    @GetMapping("/search/file-name")
    @Operation(summary = "Search backup tasks by file name prefix")
    public ResponseEntity<List<SysBackupRestore>> searchByFileName(@RequestParam String backupFileName,
                                                                   @RequestParam(defaultValue = "1") int page,
                                                                   @RequestParam(defaultValue = "20") int size) {
        return ResponseEntity.ok(backupRestoreService.searchByBackupFileNamePrefix(backupFileName, page, size));
    }

    @GetMapping("/search/handler")
    @Operation(summary = "Search backup tasks by handler")
    public ResponseEntity<List<SysBackupRestore>> searchByHandler(@RequestParam String backupHandler,
                                                                  @RequestParam(defaultValue = "1") int page,
                                                                  @RequestParam(defaultValue = "20") int size) {
        return ResponseEntity.ok(backupRestoreService.searchByBackupHandler(backupHandler, page, size));
    }

    @GetMapping("/search/restore-status")
    @Operation(summary = "Search backup tasks by restore status")
    public ResponseEntity<List<SysBackupRestore>> searchByRestoreStatus(@RequestParam String restoreStatus,
                                                                        @RequestParam(defaultValue = "1") int page,
                                                                        @RequestParam(defaultValue = "20") int size) {
        return ResponseEntity.ok(backupRestoreService.searchByRestoreStatus(restoreStatus, page, size));
    }

    @GetMapping("/search/status")
    @Operation(summary = "Search backup tasks by status")
    public ResponseEntity<List<SysBackupRestore>> searchByStatus(@RequestParam String status,
                                                                 @RequestParam(defaultValue = "1") int page,
                                                                 @RequestParam(defaultValue = "20") int size) {
        return ResponseEntity.ok(backupRestoreService.searchByStatus(status, page, size));
    }

    @GetMapping("/search/backup-time-range")
    @Operation(summary = "Search backup tasks by backup time range")
    public ResponseEntity<List<SysBackupRestore>> searchByBackupTimeRange(@RequestParam String startTime,
                                                                          @RequestParam String endTime,
                                                                          @RequestParam(defaultValue = "1") int page,
                                                                          @RequestParam(defaultValue = "20") int size) {
        return ResponseEntity.ok(backupRestoreService.searchByBackupTimeRange(startTime, endTime, page, size));
    }

    @GetMapping("/search/restore-time-range")
    @Operation(summary = "Search backup tasks by restore time range")
    public ResponseEntity<List<SysBackupRestore>> searchByRestoreTimeRange(@RequestParam String startTime,
                                                                           @RequestParam String endTime,
                                                                           @RequestParam(defaultValue = "1") int page,
                                                                           @RequestParam(defaultValue = "20") int size) {
        return ResponseEntity.ok(backupRestoreService.searchByRestoreTimeRange(startTime, endTime, page, size));
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

