package com.tutict.finalassignmentbackend.controller;

import com.tutict.finalassignmentbackend.entity.PermissionManagement;
import com.tutict.finalassignmentbackend.service.PermissionManagementService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.scheduling.annotation.Async;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;
import org.springframework.security.access.prepost.PreAuthorize;

import java.util.List;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

@RestController
@RequestMapping("/api/permissions")
public class PermissionManagementController {

    private static final ExecutorService virtualThreadExecutor = Executors.newVirtualThreadPerTaskExecutor();

    private final PermissionManagementService permissionManagementService;

    public PermissionManagementController(PermissionManagementService permissionManagementService) {
        this.permissionManagementService = permissionManagementService;
    }

    // 创建新的权限记录 (仅 ADMIN)
    @PostMapping
    @Async
    @PreAuthorize("hasRole('ADMIN')")
    public CompletableFuture<ResponseEntity<Void>> createPermission(@RequestBody PermissionManagement permission, @RequestParam String idempotencyKey) {
        return CompletableFuture.supplyAsync(() -> {
            permissionManagementService.checkAndInsertIdempotency(idempotencyKey, permission, "create");
            return ResponseEntity.status(HttpStatus.CREATED).build();
        }, virtualThreadExecutor);
    }

    // 根据权限ID获取权限信息 (USER 和 ADMIN)
    @GetMapping("/{permissionId}")
    @Async
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public CompletableFuture<ResponseEntity<PermissionManagement>> getPermissionById(@PathVariable int permissionId) {
        return CompletableFuture.supplyAsync(() -> {
            PermissionManagement permission = permissionManagementService.getPermissionById(permissionId);
            if (permission != null) {
                return ResponseEntity.ok(permission);
            } else {
                return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
            }
        }, virtualThreadExecutor);
    }

    // 获取所有权限记录 (USER 和 ADMIN)
    @GetMapping
    @Async
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public CompletableFuture<ResponseEntity<List<PermissionManagement>>> getAllPermissions() {
        return CompletableFuture.supplyAsync(() -> {
            List<PermissionManagement> permissions = permissionManagementService.getAllPermissions();
            return ResponseEntity.ok(permissions);
        }, virtualThreadExecutor);
    }

    // 根据权限名称获取权限信息 (USER 和 ADMIN)
    @GetMapping("/name/{permissionName}")
    @Async
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public CompletableFuture<ResponseEntity<PermissionManagement>> getPermissionByName(@PathVariable String permissionName) {
        return CompletableFuture.supplyAsync(() -> {
            PermissionManagement permission = permissionManagementService.getPermissionByName(permissionName);
            if (permission != null) {
                return ResponseEntity.ok(permission);
            } else {
                return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
            }
        }, virtualThreadExecutor);
    }

    // 根据权限名称模糊匹配获取权限信息 (USER 和 ADMIN)
    @GetMapping("/search")
    @Async
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public CompletableFuture<ResponseEntity<List<PermissionManagement>>> getPermissionsByNameLike(@RequestParam String name) {
        return CompletableFuture.supplyAsync(() -> {
            List<PermissionManagement> permissions = permissionManagementService.getPermissionsByNameLike(name);
            return ResponseEntity.ok(permissions);
        }, virtualThreadExecutor);
    }

    // 更新指定权限的信息 (仅 ADMIN)
    @PutMapping("/{permissionId}")
    @Async
    @Transactional
    @PreAuthorize("hasRole('ADMIN')")
    public CompletableFuture<ResponseEntity<PermissionManagement>> updatePermission(@PathVariable int permissionId, @RequestBody PermissionManagement updatedPermission, @RequestParam String idempotencyKey) {
        return CompletableFuture.supplyAsync(() -> {
            PermissionManagement existingPermission = permissionManagementService.getPermissionById(permissionId);
            if (existingPermission != null) {
                updatedPermission.setPermissionId(permissionId);
                permissionManagementService.checkAndInsertIdempotency(idempotencyKey, updatedPermission, "update");
                return ResponseEntity.ok(updatedPermission);
            } else {
                return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
            }
        }, virtualThreadExecutor);
    }

    // 删除指定权限的记录 (仅 ADMIN)
    @DeleteMapping("/{permissionId}")
    @Async
    @PreAuthorize("hasRole('ADMIN')")
    public CompletableFuture<ResponseEntity<Void>> deletePermission(@PathVariable int permissionId) {
        return CompletableFuture.supplyAsync(() -> {
            permissionManagementService.deletePermission(permissionId);
            return ResponseEntity.noContent().build();
        }, virtualThreadExecutor);
    }

    // 根据权限名称删除权限记录 (仅 ADMIN)
    @DeleteMapping("/name/{permissionName}")
    @Async
    @PreAuthorize("hasRole('ADMIN')")
    public CompletableFuture<ResponseEntity<Void>> deletePermissionByName(@PathVariable String permissionName) {
        return CompletableFuture.supplyAsync(() -> {
            permissionManagementService.deletePermissionByName(permissionName);
            return ResponseEntity.noContent().build();
        }, virtualThreadExecutor);
    }
}