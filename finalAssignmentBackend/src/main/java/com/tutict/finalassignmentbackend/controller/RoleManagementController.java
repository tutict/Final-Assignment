package com.tutict.finalassignmentbackend.controller;

import com.tutict.finalassignmentbackend.entity.RoleManagement;
import com.tutict.finalassignmentbackend.service.RoleManagementService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;
import org.springframework.security.access.prepost.PreAuthorize;

import java.util.List;

@RestController
@RequestMapping("/api/roles")
public class RoleManagementController {

    private final RoleManagementService roleManagementService;

    public RoleManagementController(RoleManagementService roleManagementService) {
        this.roleManagementService = roleManagementService;
    }

    // 创建新的角色记录 (仅 ADMIN)
    @PostMapping
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Void> createRole(@RequestBody RoleManagement role, @RequestParam String idempotencyKey) {
        roleManagementService.checkAndInsertIdempotency(idempotencyKey, role, "create");
        return ResponseEntity.status(HttpStatus.CREATED).build();
    }

    // 根据角色ID获取角色信息 (USER 和 ADMIN)
    @GetMapping("/{roleId}")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public ResponseEntity<RoleManagement> getRoleById(@PathVariable int roleId) {
        RoleManagement role = roleManagementService.getRoleById(roleId);
        if (role != null) {
            return ResponseEntity.ok(role);
        } else {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
        }
    }

    // 获取所有角色信息 (USER 和 ADMIN)
    @GetMapping
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public ResponseEntity<List<RoleManagement>> getAllRoles() {
        List<RoleManagement> roles = roleManagementService.getAllRoles();
        return ResponseEntity.ok(roles);
    }

    // 根据角色名称获取角色信息 (USER 和 ADMIN)
    @GetMapping("/name/{roleName}")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public ResponseEntity<RoleManagement> getRoleByName(@PathVariable String roleName) {
        RoleManagement role = roleManagementService.getRoleByName(roleName);
        if (role != null) {
            return ResponseEntity.ok(role);
        } else {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
        }
    }

    // 根据角色名称模糊匹配获取角色信息 (USER 和 ADMIN)
    @GetMapping("/search")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public ResponseEntity<List<RoleManagement>> getRolesByNameLike(@RequestParam String name) {
        List<RoleManagement> roles = roleManagementService.getRolesByNameLike(name);
        return ResponseEntity.ok(roles);
    }

    // 更新指定角色的信息 (仅 ADMIN)
    @PutMapping("/{roleId}")
    @Transactional
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<RoleManagement> updateRole(@PathVariable int roleId, @RequestBody RoleManagement updatedRole, @RequestParam String idempotencyKey) {
        RoleManagement existingRole = roleManagementService.getRoleById(roleId);
        if (existingRole != null) {
            updatedRole.setRoleId(roleId);
            roleManagementService.checkAndInsertIdempotency(idempotencyKey, updatedRole, "update");
            return ResponseEntity.ok(updatedRole);
        } else {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
        }
    }

    // 删除指定角色记录 (仅 ADMIN)
    @DeleteMapping("/{roleId}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Void> deleteRole(@PathVariable int roleId) {
        roleManagementService.deleteRole(roleId);
        return ResponseEntity.noContent().build();
    }

    // 根据角色名称删除角色记录 (仅 ADMIN)
    @DeleteMapping("/name/{roleName}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Void> deleteRoleByName(@PathVariable String roleName) {
        roleManagementService.deleteRoleByName(roleName);
        return ResponseEntity.noContent().build();
    }
}