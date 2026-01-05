package com.tutict.finalassignmentbackend.controller;

import com.tutict.finalassignmentbackend.entity.SysPermission;
import com.tutict.finalassignmentbackend.service.SysPermissionService;
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
@RequestMapping("/api/permissions")
@Tag(name = "Permission Management", description = "系统权限管理接口")
@SecurityRequirement(name = "bearerAuth")
@RolesAllowed({"SUPER_ADMIN", "ADMIN"})
public class PermissionManagementController {

    private static final Logger LOG = Logger.getLogger(PermissionManagementController.class.getName());

    private final SysPermissionService sysPermissionService;

    public PermissionManagementController(SysPermissionService sysPermissionService) {
        this.sysPermissionService = sysPermissionService;
    }

    @PostMapping
    @Operation(summary = "创建权限")
    public ResponseEntity<SysPermission> create(@RequestBody SysPermission request,
                                                @RequestHeader(value = "Idempotency-Key", required = false)
                                                String idempotencyKey) {
        boolean useKey = hasKey(idempotencyKey);
        try {
            if (useKey) {
                if (sysPermissionService.shouldSkipProcessing(idempotencyKey)) {
                    return ResponseEntity.status(HttpStatus.ALREADY_REPORTED).build();
                }
                sysPermissionService.checkAndInsertIdempotency(idempotencyKey, request, "create");
            }
            SysPermission saved = sysPermissionService.createSysPermission(request);
            if (useKey && saved.getPermissionId() != null) {
                sysPermissionService.markHistorySuccess(idempotencyKey, saved.getPermissionId());
            }
            return ResponseEntity.status(HttpStatus.CREATED).body(saved);
        } catch (Exception ex) {
            if (useKey) {
                sysPermissionService.markHistoryFailure(idempotencyKey, ex.getMessage());
            }
            LOG.log(Level.SEVERE, "Create permission failed", ex);
            return ResponseEntity.status(resolveStatus(ex)).build();
        }
    }

    @PutMapping("/{permissionId}")
    @Operation(summary = "更新权限")
    public ResponseEntity<SysPermission> update(@PathVariable Integer permissionId,
                                                @RequestBody SysPermission request,
                                                @RequestHeader(value = "Idempotency-Key", required = false)
                                                String idempotencyKey) {
        boolean useKey = hasKey(idempotencyKey);
        try {
            request.setPermissionId(permissionId);
            if (useKey) {
                sysPermissionService.checkAndInsertIdempotency(idempotencyKey, request, "update");
            }
            SysPermission updated = sysPermissionService.updateSysPermission(request);
            if (useKey && updated.getPermissionId() != null) {
                sysPermissionService.markHistorySuccess(idempotencyKey, updated.getPermissionId());
            }
            return ResponseEntity.ok(updated);
        } catch (Exception ex) {
            if (useKey) {
                sysPermissionService.markHistoryFailure(idempotencyKey, ex.getMessage());
            }
            LOG.log(Level.SEVERE, "Update permission failed", ex);
            return ResponseEntity.status(resolveStatus(ex)).build();
        }
    }

    @DeleteMapping("/{permissionId}")
    @Operation(summary = "删除权限")
    public ResponseEntity<Void> delete(@PathVariable Integer permissionId) {
        try {
            sysPermissionService.deleteSysPermission(permissionId);
            return ResponseEntity.noContent().build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Delete permission failed", ex);
            return ResponseEntity.status(resolveStatus(ex)).build();
        }
    }

    @GetMapping("/{permissionId}")
    @Operation(summary = "查询权限详情")
    public ResponseEntity<SysPermission> get(@PathVariable Integer permissionId) {
        try {
            SysPermission permission = sysPermissionService.findById(permissionId);
            return permission == null ? ResponseEntity.notFound().build() : ResponseEntity.ok(permission);
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Get permission failed", ex);
            return ResponseEntity.status(resolveStatus(ex)).build();
        }
    }

    @GetMapping
    @Operation(summary = "查询全部权限")
    public ResponseEntity<List<SysPermission>> list() {
        try {
            return ResponseEntity.ok(sysPermissionService.findAll());
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "List permissions failed", ex);
            return ResponseEntity.status(resolveStatus(ex)).build();
        }
    }

    @GetMapping("/parent/{parentId}")
    @Operation(summary = "按父节点查询权限")
    public ResponseEntity<List<SysPermission>> listByParent(@PathVariable Integer parentId,
                                                            @RequestParam(defaultValue = "1") int page,
                                                            @RequestParam(defaultValue = "50") int size) {
        try {
            return ResponseEntity.ok(sysPermissionService.findByParentId(parentId, page, size));
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "List permissions by parent failed", ex);
            return ResponseEntity.status(resolveStatus(ex)).build();
        }
    }

    @GetMapping("/search/code/prefix")
    @Operation(summary = "Search permissions by code prefix")
    public ResponseEntity<List<SysPermission>> searchByCodePrefix(@RequestParam String permissionCode,
                                                                  @RequestParam(defaultValue = "1") int page,
                                                                  @RequestParam(defaultValue = "50") int size) {
        return ResponseEntity.ok(sysPermissionService.searchByPermissionCodePrefix(permissionCode, page, size));
    }

    @GetMapping("/search/code/fuzzy")
    @Operation(summary = "Search permissions by code fuzzy")
    public ResponseEntity<List<SysPermission>> searchByCodeFuzzy(@RequestParam String permissionCode,
                                                                 @RequestParam(defaultValue = "1") int page,
                                                                 @RequestParam(defaultValue = "50") int size) {
        return ResponseEntity.ok(sysPermissionService.searchByPermissionCodeFuzzy(permissionCode, page, size));
    }

    @GetMapping("/search/name/prefix")
    @Operation(summary = "Search permissions by name prefix")
    public ResponseEntity<List<SysPermission>> searchByNamePrefix(@RequestParam String permissionName,
                                                                  @RequestParam(defaultValue = "1") int page,
                                                                  @RequestParam(defaultValue = "50") int size) {
        return ResponseEntity.ok(sysPermissionService.searchByPermissionNamePrefix(permissionName, page, size));
    }

    @GetMapping("/search/name/fuzzy")
    @Operation(summary = "Search permissions by name fuzzy")
    public ResponseEntity<List<SysPermission>> searchByNameFuzzy(@RequestParam String permissionName,
                                                                 @RequestParam(defaultValue = "1") int page,
                                                                 @RequestParam(defaultValue = "50") int size) {
        return ResponseEntity.ok(sysPermissionService.searchByPermissionNameFuzzy(permissionName, page, size));
    }

    @GetMapping("/search/type")
    @Operation(summary = "Search permissions by type")
    public ResponseEntity<List<SysPermission>> searchByType(@RequestParam String permissionType,
                                                            @RequestParam(defaultValue = "1") int page,
                                                            @RequestParam(defaultValue = "50") int size) {
        return ResponseEntity.ok(sysPermissionService.searchByPermissionType(permissionType, page, size));
    }

    @GetMapping("/search/api-path")
    @Operation(summary = "Search permissions by API path prefix")
    public ResponseEntity<List<SysPermission>> searchByApiPath(@RequestParam String apiPath,
                                                               @RequestParam(defaultValue = "1") int page,
                                                               @RequestParam(defaultValue = "50") int size) {
        return ResponseEntity.ok(sysPermissionService.searchByApiPathPrefix(apiPath, page, size));
    }

    @GetMapping("/search/menu-path")
    @Operation(summary = "Search permissions by menu path prefix")
    public ResponseEntity<List<SysPermission>> searchByMenuPath(@RequestParam String menuPath,
                                                                @RequestParam(defaultValue = "1") int page,
                                                                @RequestParam(defaultValue = "50") int size) {
        return ResponseEntity.ok(sysPermissionService.searchByMenuPathPrefix(menuPath, page, size));
    }

    @GetMapping("/search/visible")
    @Operation(summary = "Search permissions by visibility")
    public ResponseEntity<List<SysPermission>> searchByVisible(@RequestParam boolean isVisible,
                                                               @RequestParam(defaultValue = "1") int page,
                                                               @RequestParam(defaultValue = "50") int size) {
        return ResponseEntity.ok(sysPermissionService.searchByIsVisible(isVisible, page, size));
    }

    @GetMapping("/search/external")
    @Operation(summary = "Search permissions by external flag")
    public ResponseEntity<List<SysPermission>> searchByExternal(@RequestParam boolean isExternal,
                                                                @RequestParam(defaultValue = "1") int page,
                                                                @RequestParam(defaultValue = "50") int size) {
        return ResponseEntity.ok(sysPermissionService.searchByIsExternal(isExternal, page, size));
    }

    @GetMapping("/search/status")
    @Operation(summary = "Search permissions by status")
    public ResponseEntity<List<SysPermission>> searchByStatus(@RequestParam String status,
                                                              @RequestParam(defaultValue = "1") int page,
                                                              @RequestParam(defaultValue = "50") int size) {
        return ResponseEntity.ok(sysPermissionService.searchByStatus(status, page, size));
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
