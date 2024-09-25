package com.tutict.finalassignmentbackend.controller;

import com.tutict.finalassignmentbackend.entity.PermissionManagement;
import com.tutict.finalassignmentbackend.service.PermissionManagementService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
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

// 控制器类，用于管理权限相关操作
@RestController
@RequestMapping("/eventbus/permissions")
public class PermissionManagementController {

    // 权限管理服务的依赖项
    private final PermissionManagementService permissionManagementService;

    // 构造函数，通过依赖注入初始化权限管理服务
    @Autowired
    public PermissionManagementController(PermissionManagementService permissionManagementService) {
        this.permissionManagementService = permissionManagementService;
    }

    // 创建权限的接口
    // 接收权限信息并将其创建
    @PostMapping
    public ResponseEntity<Void> createPermission(@RequestBody PermissionManagement permission) {
        permissionManagementService.createPermission(permission);
        return ResponseEntity.status(HttpStatus.CREATED).build();
    }

    // 根据ID获取权限的接口
    // 如果找到对应的权限，则返回OK状态和权限信息
    // 如果未找到，则返回NotFound状态
    @GetMapping("/{permissionId}")
    public ResponseEntity<PermissionManagement> getPermissionById(@PathVariable int permissionId) {
        PermissionManagement permission = permissionManagementService.getPermissionById(permissionId);
        if (permission != null) {
            return ResponseEntity.ok(permission);
        } else {
            return ResponseEntity.notFound().build();
        }
    }

    // 获取所有权限的接口
    // 返回所有权限的信息
    @GetMapping
    public ResponseEntity<List<PermissionManagement>> getAllPermissions() {
        List<PermissionManagement> permissions = permissionManagementService.getAllPermissions();
        return ResponseEntity.ok(permissions);
    }

    // 根据名称获取权限的接口
    // 如果找到对应的权限，则返回OK状态和权限信息
    // 如果未找到，则返回NotFound状态
    @GetMapping("/name/{permissionName}")
    public ResponseEntity<PermissionManagement> getPermissionByName(@PathVariable String permissionName) {
        PermissionManagement permission = permissionManagementService.getPermissionByName(permissionName);
        if (permission != null) {
            return ResponseEntity.ok(permission);
        } else {
            return ResponseEntity.notFound().build();
        }
    }

    // 根据名称模糊查询权限的接口
    // 返回匹配权限名称的权限列表
    @GetMapping("/search")
    public ResponseEntity<List<PermissionManagement>> getPermissionsByNameLike(@RequestParam("name") String permissionName) {
        List<PermissionManagement> permissions = permissionManagementService.getPermissionsByNameLike(permissionName);
        return ResponseEntity.ok(permissions);
    }

    // 更新权限的接口
    // 根据ID查找权限，如果找到则更新权限信息，否则返回NotFound状态
    @PutMapping("/{permissionId}")
    public ResponseEntity<Void> updatePermission(@PathVariable int permissionId, @RequestBody PermissionManagement updatedPermission) {
        PermissionManagement existingPermission = permissionManagementService.getPermissionById(permissionId);
        if (existingPermission != null) {
            updatedPermission.setPermissionId(permissionId);
            permissionManagementService.updatePermission(updatedPermission);
            return ResponseEntity.ok().build();
        } else {
            return ResponseEntity.notFound().build();
        }
    }

    // 删除权限的接口
    // 根据ID删除权限，成功后返回NoContent状态
    @DeleteMapping("/{permissionId}")
    public ResponseEntity<Void> deletePermission(@PathVariable int permissionId) {
        permissionManagementService.deletePermission(permissionId);
        return ResponseEntity.noContent().build();
    }

    // 根据名称删除权限的接口
    // 删除指定名称的权限，成功后返回NoContent状态
    @DeleteMapping("/name/{permissionName}")
    public ResponseEntity<Void> deletePermissionByName(@PathVariable String permissionName) {
        permissionManagementService.deletePermissionByName(permissionName);
        return ResponseEntity.noContent().build();
    }
}
