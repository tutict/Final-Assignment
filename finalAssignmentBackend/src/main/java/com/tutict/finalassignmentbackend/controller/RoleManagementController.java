package com.tutict.finalassignmentbackend.controller;

import com.tutict.finalassignmentbackend.entity.RoleManagement;
import com.tutict.finalassignmentbackend.service.RoleManagementService;
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

// 控制器类，用于管理角色相关操作
@RestController
@RequestMapping("/eventbus/roles")
public class RoleManagementController {

    // 角色管理服务的依赖项
    private final RoleManagementService roleManagementService;

    // 构造函数，通过依赖注入初始化角色管理服务
    @Autowired
    public RoleManagementController(RoleManagementService roleManagementService) {
        this.roleManagementService = roleManagementService;
    }

    // 创建一个新角色
    // 接受一个包含角色信息的请求体
    // 返回状态码201 Created，表示角色已成功创建
    @PostMapping
    public ResponseEntity<Void> createRole(@RequestBody RoleManagement role) {
        roleManagementService.createRole(role);
        return ResponseEntity.status(HttpStatus.CREATED).build();
    }

    // 根据角色ID获取角色信息
    // 接受路径变量roleId作为输入
    // 如果找到角色，返回状态码200 OK和角色信息
    // 如果未找到角色，返回状态码204 No Content
    @GetMapping("/{roleId}")
    public ResponseEntity<RoleManagement> getRoleById(@PathVariable int roleId) {
        RoleManagement role = roleManagementService.getRoleById(roleId);
        if (role != null) {
            return ResponseEntity.ok(role);
        } else {
            return ResponseEntity.notFound().build();
        }
    }

    // 获取所有角色的信息列表
    // 返回状态码200 OK和角色列表
    @GetMapping
    public ResponseEntity<List<RoleManagement>> getAllRoles() {
        List<RoleManagement> roles = roleManagementService.getAllRoles();
        return ResponseEntity.ok(roles);
    }

    // 根据角色名称获取角色信息
    // 接受路径变量roleName作为输入
    // 如果找到角色，返回状态码200 OK和角色信息
    // 如果未找到角色，返回状态码204 No Content
    @GetMapping("/name/{roleName}")
    public ResponseEntity<RoleManagement> getRoleByName(@PathVariable String roleName) {
        RoleManagement role = roleManagementService.getRoleByName(roleName);
        if (role != null) {
            return ResponseEntity.ok(role);
        } else {
            return ResponseEntity.notFound().build();
        }
    }

    // 搜索名称相似的角色信息列表
    // 接受请求参数name作为输入
    // 返回状态码200 OK和角色列表
    @GetMapping("/search")
    public ResponseEntity<List<RoleManagement>> getRolesByNameLike(@RequestParam("name") String roleName) {
        List<RoleManagement> roles = roleManagementService.getRolesByNameLike(roleName);
        return ResponseEntity.ok(roles);
    }

    // 更新角色信息
    // 接受路径变量roleId和请求体中的角色信息作为输入
    // 如果找到角色，更新角色信息并返回状态码200 OK
    // 如果未找到角色，返回状态码204 No Content
    @PutMapping("/{roleId}")
    public ResponseEntity<Void> updateRole(@PathVariable int roleId, @RequestBody RoleManagement updatedRole) {
        RoleManagement existingRole = roleManagementService.getRoleById(roleId);
        if (existingRole != null) {
            updatedRole.setRoleId(roleId);
            roleManagementService.updateRole(updatedRole);
            return ResponseEntity.ok().build();
        } else {
            return ResponseEntity.notFound().build();
        }
    }

    // 删除角色
    // 接受路径变量roleId作为输入
    // 返回状态码204 No Content，表示角色已成功删除
    @DeleteMapping("/{roleId}")
    public ResponseEntity<Void> deleteRole(@PathVariable int roleId) {
        roleManagementService.deleteRole(roleId);
        return ResponseEntity.noContent().build();
    }

    // 根据角色名称删除角色
    // 接受路径变量roleName作为输入
    // 返回状态码204 No Content，表示角色已成功删除
    @DeleteMapping("/name/{roleName}")
    public ResponseEntity<Void> deleteRoleByName(@PathVariable String roleName) {
        roleManagementService.deleteRoleByName(roleName);
        return ResponseEntity.noContent().build();
    }
}
