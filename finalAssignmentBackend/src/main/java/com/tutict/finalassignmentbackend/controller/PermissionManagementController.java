package com.tutict.finalassignmentbackend.controller;

import com.tutict.finalassignmentbackend.entity.PermissionManagement;
import com.tutict.finalassignmentbackend.service.PermissionManagementService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;
import org.springframework.security.access.prepost.PreAuthorize;

import java.util.List;

@RestController
@RequestMapping("/api/permissions")
public class PermissionManagementController {

    private final PermissionManagementService permissionManagementService;

    public PermissionManagementController(PermissionManagementService permissionManagementService) {
        this.permissionManagementService = permissionManagementService;
    }

    // 创建新的权限记录 (仅 ADMIN)
    @PostMapping
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Void> createPermission(@RequestBody PermissionManagement permission, @RequestParam String idempotencyKey) {
        permissionManagementService.checkAndInsertIdempotency(idempotencyKey, permission, "create");
        return ResponseEntity.status(HttpStatus.CREATED).build();
    }

    // 根据权限ID获取权限信息 (USER 和 ADMIN)
    @GetMapping("/{permissionId}")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public ResponseEntity<PermissionManagement> getPermissionById(@PathVariable int permissionId) {
        PermissionManagement permission = permissionManagementService.getPermissionById(permissionId);
        if (permission != null) {
            return ResponseEntity.ok(permission);
        } else {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
        }
    }

    // 获取所有权限记录 (USER 和 ADMIN)
    @GetMapping
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public ResponseEntity<List<PermissionManagement>> getAllPermissions() {
        List<PermissionManagement> permissions = permissionManagementService.getAllPermissions();
        return ResponseEntity.ok(permissions);
    }

    // 根据权限名称获取权限信息 (USER 和 ADMIN)
    @GetMapping("/name/{permissionName}")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public ResponseEntity<PermissionManagement> getPermissionByName(@PathVariable String permissionName) {
        PermissionManagement permission = permissionManagementService.getPermissionByName(permissionName);
        if (permission != null) {
            return ResponseEntity.ok(permission);
        } else {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
        }
    }

    // 根据权限名称模糊匹配获取权限信息 (USER 和 ADMIN)
    @GetMapping("/search")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public ResponseEntity<List<PermissionManagement>> getPermissionsByNameLike(@RequestParam String name) {
        List<PermissionManagement> permissions = permissionManagementService.getPermissionsByNameLike(name);
        return ResponseEntity.ok(permissions);
    }

    // 更新指定权限的信息 (仅 ADMIN)
    @PutMapping("/{permissionId}")
    @Transactional
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<PermissionManagement> updatePermission(@PathVariable int permissionId, @RequestBody PermissionManagement updatedPermission, @RequestParam String idempotencyKey) {
        PermissionManagement existingPermission = permissionManagementService.getPermissionById(permissionId);
        if (existingPermission != null) {
            updatedPermission.setPermissionId(permissionId);
            permissionManagementService.checkAndInsertIdempotency(idempotencyKey, updatedPermission, "update");
            return ResponseEntity.ok(updatedPermission);
        } else {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
        }
    }

    // 删除指定权限的记录 (仅 ADMIN)
    @DeleteMapping("/{permissionId}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Void> deletePermission(@PathVariable int permissionId) {
        permissionManagementService.deletePermission(permissionId);
        return ResponseEntity.noContent().build();
    }

    // 根据权限名称删除权限记录 (仅 ADMIN)
    @DeleteMapping("/name/{permissionName}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Void> deletePermissionByName(@PathVariable String permissionName) {
        permissionManagementService.deletePermissionByName(permissionName);
        return ResponseEntity.noContent().build();
    }
}