package com.tutict.finalassignmentbackend.controller;

import com.tutict.finalassignmentbackend.entity.RoleManagement;
import com.tutict.finalassignmentbackend.service.RoleManagementService;
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
@RequestMapping("/api/roles")
public class RoleManagementController {

    private static final ExecutorService virtualThreadExecutor = Executors.newVirtualThreadPerTaskExecutor();

    private final RoleManagementService roleManagementService;

    public RoleManagementController(RoleManagementService roleManagementService) {
        this.roleManagementService = roleManagementService;
    }

    // 创建新的角色记录
    @PostMapping
    @Async
    public CompletableFuture<ResponseEntity<Void>> createRole(@RequestBody RoleManagement role, @RequestParam String idempotencyKey) {
        return CompletableFuture.supplyAsync(() -> {
            roleManagementService.checkAndInsertIdempotency(idempotencyKey, role, "create");
            return ResponseEntity.status(HttpStatus.CREATED).build();
        }, virtualThreadExecutor);
    }

    // 根据角色ID获取角色信息
    @GetMapping("/{roleId}")
    @Async
    public CompletableFuture<ResponseEntity<RoleManagement>> getRoleById(@PathVariable int roleId) {
        return CompletableFuture.supplyAsync(() -> {
            RoleManagement role = roleManagementService.getRoleById(roleId);
            if (role != null) {
                return ResponseEntity.ok(role);
            } else {
                return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
            }
        }, virtualThreadExecutor);
    }

    // 获取所有角色信息
    @GetMapping
    @Async
    public CompletableFuture<ResponseEntity<List<RoleManagement>>> getAllRoles() {
        return CompletableFuture.supplyAsync(() -> {
            List<RoleManagement> roles = roleManagementService.getAllRoles();
            return ResponseEntity.ok(roles);
        }, virtualThreadExecutor);
    }

    // 根据角色名称获取角色信息
    @GetMapping("/name/{roleName}")
    @Async
    public CompletableFuture<ResponseEntity<RoleManagement>> getRoleByName(@PathVariable String roleName) {
        return CompletableFuture.supplyAsync(() -> {
            RoleManagement role = roleManagementService.getRoleByName(roleName);
            if (role != null) {
                return ResponseEntity.ok(role);
            } else {
                return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
            }
        }, virtualThreadExecutor);
    }

    // 根据角色名称模糊匹配获取角色信息
    @GetMapping("/search")
    @Async
    public CompletableFuture<ResponseEntity<List<RoleManagement>>> getRolesByNameLike(@RequestParam String name) {
        return CompletableFuture.supplyAsync(() -> {
            List<RoleManagement> roles = roleManagementService.getRolesByNameLike(name);
            return ResponseEntity.ok(roles);
        }, virtualThreadExecutor);
    }

    // 更新指定角色的信息
    @PutMapping("/{roleId}")
    @Async
    @Transactional
    public CompletableFuture<ResponseEntity<RoleManagement>> updateRole(@PathVariable int roleId, @RequestBody RoleManagement updatedRole, @RequestParam String idempotencyKey) {
        return CompletableFuture.supplyAsync(() -> {
            RoleManagement existingRole = roleManagementService.getRoleById(roleId);
            if (existingRole != null) {
                updatedRole.setRoleId(roleId);
                roleManagementService.checkAndInsertIdempotency(idempotencyKey, updatedRole, "update");
                return ResponseEntity.ok(updatedRole);
            } else {
                return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
            }
        }, virtualThreadExecutor);
    }

    // 删除指定角色记录
    @DeleteMapping("/{roleId}")
    @Async
    public CompletableFuture<ResponseEntity<Void>> deleteRole(@PathVariable int roleId) {
        return CompletableFuture.supplyAsync(() -> {
            roleManagementService.deleteRole(roleId);
            return ResponseEntity.noContent().build();
        }, virtualThreadExecutor);
    }

    // 根据角色名称删除角色记录
    @DeleteMapping("/name/{roleName}")
    @Async
    public CompletableFuture<ResponseEntity<Void>> deleteRoleByName(@PathVariable String roleName) {
        return CompletableFuture.supplyAsync(() -> {
            roleManagementService.deleteRoleByName(roleName);
            return ResponseEntity.noContent().build();
        }, virtualThreadExecutor);
    }
}
