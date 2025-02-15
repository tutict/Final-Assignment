package com.tutict.finalassignmentbackend.controller;

import com.tutict.finalassignmentbackend.entity.PermissionManagement;
import com.tutict.finalassignmentbackend.service.PermissionManagementService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.scheduling.annotation.Async;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

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

    // 创建新的权限记录
    @PostMapping
    @Async
    public CompletableFuture<ResponseEntity<Void>> createPermission(@RequestBody PermissionManagement permission, @RequestParam String idempotencyKey) {
        return CompletableFuture.supplyAsync(() -> {
            permissionManagementService.checkAndInsertIdempotency(idempotencyKey, permission, "create");
            return ResponseEntity.status(HttpStatus.CREATED).build();
        }, virtualThreadExecutor);
    }

    // 根据权限ID获取权限信息
    @GetMapping("/{permissionId}")
    @Async
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

    // 获取所有权限记录
    @GetMapping
    @Async
    public CompletableFuture<ResponseEntity<List<PermissionManagement>>> getAllPermissions() {
        return CompletableFuture.supplyAsync(() -> {
            List<PermissionManagement> permissions = permissionManagementService.getAllPermissions();
            return ResponseEntity.ok(permissions);
        }, virtualThreadExecutor);
    }

    // 根据权限名称获取权限信息
    @GetMapping("/name/{permissionName}")
    @Async
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

    // 根据权限名称模糊匹配获取权限信息
    @GetMapping("/search")
    @Async
    public CompletableFuture<ResponseEntity<List<PermissionManagement>>> getPermissionsByNameLike(@RequestParam String name) {
        return CompletableFuture.supplyAsync(() -> {
            List<PermissionManagement> permissions = permissionManagementService.getPermissionsByNameLike(name);
            return ResponseEntity.ok(permissions);
        }, virtualThreadExecutor);
    }

    // 更新指定权限的信息
    @PutMapping("/{permissionId}")
    @Async
    @Transactional
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

    // 删除指定权限的记录
    @DeleteMapping("/{permissionId}")
    @Async
    public CompletableFuture<ResponseEntity<Void>> deletePermission(@PathVariable int permissionId) {
        return CompletableFuture.supplyAsync(() -> {
            permissionManagementService.deletePermission(permissionId);
            return ResponseEntity.noContent().build();
        }, virtualThreadExecutor);
    }

    // 根据权限名称删除权限记录
    @DeleteMapping("/name/{permissionName}")
    @Async
    public CompletableFuture<ResponseEntity<Void>> deletePermissionByName(@PathVariable String permissionName) {
        return CompletableFuture.supplyAsync(() -> {
            permissionManagementService.deletePermissionByName(permissionName);
            return ResponseEntity.noContent().build();
        }, virtualThreadExecutor);
    }
}
