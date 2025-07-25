package com.tutict.finalassignmentbackend.controller;

import com.tutict.finalassignmentbackend.entity.RoleManagement;
import com.tutict.finalassignmentbackend.service.RoleManagementService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;
import org.springframework.security.access.prepost.PreAuthorize;

import java.util.List;

@RestController
@RequestMapping("/api/roles")
@SecurityRequirement(name = "bearerAuth")
@Tag(name = "Role Management", description = "APIs for managing role records")
public class RoleManagementController {

    private final RoleManagementService roleManagementService;

    public RoleManagementController(RoleManagementService roleManagementService) {
        this.roleManagementService = roleManagementService;
    }

    @PostMapping
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(
            summary = "创建角色记录",
            description = "管理员创建新的角色记录，仅限 ADMIN 角色。需要提供幂等键以防止重复提交。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "201", description = "角色记录创建成功"),
            @ApiResponse(responseCode = "400", description = "无效的输入参数或幂等键冲突"),
            @ApiResponse(responseCode = "403", description = "无权限访问，仅限 ADMIN 角色"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<Void> createRole(
            @RequestBody @Parameter(description = "角色记录的详细信息", required = true) RoleManagement role,
            @RequestParam @Parameter(description = "幂等键，用于防止重复提交", required = true) String idempotencyKey) {
        roleManagementService.checkAndInsertIdempotency(idempotencyKey, role, "create");
        return ResponseEntity.status(HttpStatus.CREATED).build();
    }

    @GetMapping("/{roleId}")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    @Operation(
            summary = "根据ID获取角色记录",
            description = "获取指定ID的角色记录，USER 和 ADMIN 角色均可访问。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "成功返回角色记录"),
            @ApiResponse(responseCode = "403", description = "无权限访问，需 USER 或 ADMIN 角色"),
            @ApiResponse(responseCode = "404", description = "未找到角色记录"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<RoleManagement> getRoleById(
            @PathVariable @Parameter(description = "角色ID", required = true) int roleId) {
        RoleManagement role = roleManagementService.getRoleById(roleId);
        if (role != null) {
            return ResponseEntity.ok(role);
        } else {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
        }
    }

    @GetMapping
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    @Operation(
            summary = "获取所有角色记录",
            description = "获取所有角色记录的列表，USER 和 ADMIN 角色均可访问。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "成功返回角色记录列表"),
            @ApiResponse(responseCode = "403", description = "无权限访问，需 USER 或 ADMIN 角色"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<List<RoleManagement>> getAllRoles() {
        List<RoleManagement> roles = roleManagementService.getAllRoles();
        return ResponseEntity.ok(roles);
    }

    @GetMapping("/name/{roleName}")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    @Operation(
            summary = "根据角色名称获取角色记录",
            description = "获取指定角色名称的角色记录，USER 和 ADMIN 角色均可访问。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "成功返回角色记录"),
            @ApiResponse(responseCode = "403", description = "无权限访问，需 USER 或 ADMIN 角色"),
            @ApiResponse(responseCode = "404", description = "未找到角色记录"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<RoleManagement> getRoleByName(
            @PathVariable @Parameter(description = "角色名称", required = true) String roleName) {
        RoleManagement role = roleManagementService.getRoleByName(roleName);
        if (role != null) {
            return ResponseEntity.ok(role);
        } else {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
        }
    }

    @GetMapping("/search")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    @Operation(
            summary = "根据角色名称模糊搜索角色记录",
            description = "根据角色名称模糊匹配获取角色记录列表，USER 和 ADMIN 角色均可访问。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "成功返回角色记录列表"),
            @ApiResponse(responseCode = "403", description = "无权限访问，需 USER 或 ADMIN 角色"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<List<RoleManagement>> getRolesByNameLike(
            @RequestParam @Parameter(description = "角色名称查询字符串", required = true) String name) {
        List<RoleManagement> roles = roleManagementService.getRolesByNameLike(name);
        return ResponseEntity.ok(roles);
    }

    @PutMapping("/{roleId}")
    @Transactional
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(
            summary = "更新角色记录",
            description = "管理员更新指定ID的角色记录，需要提供幂等键以防止重复提交。操作在事务中执行。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "角色记录更新成功"),
            @ApiResponse(responseCode = "400", description = "无效的输入参数或幂等键冲突"),
            @ApiResponse(responseCode = "403", description = "无权限访问，仅限 ADMIN 角色"),
            @ApiResponse(responseCode = "404", description = "未找到角色记录"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<RoleManagement> updateRole(
            @PathVariable @Parameter(description = "角色ID", required = true) int roleId,
            @RequestBody @Parameter(description = "更新后的角色记录信息", required = true) RoleManagement updatedRole,
            @RequestParam @Parameter(description = "幂等键，用于防止重复提交", required = true) String idempotencyKey) {
        RoleManagement existingRole = roleManagementService.getRoleById(roleId);
        if (existingRole != null) {
            updatedRole.setRoleId(roleId);
            roleManagementService.checkAndInsertIdempotency(idempotencyKey, updatedRole, "update");
            return ResponseEntity.ok(updatedRole);
        } else {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
        }
    }

    @DeleteMapping("/{roleId}")
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(
            summary = "根据ID删除角色记录",
            description = "管理员删除指定ID的角色记录，仅限 ADMIN 角色。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "204", description = "角色记录删除成功"),
            @ApiResponse(responseCode = "403", description = "无权限访问，仅限 ADMIN 角色"),
            @ApiResponse(responseCode = "404", description = "未找到角色记录"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<Void> deleteRole(
            @PathVariable @Parameter(description = "角色ID", required = true) int roleId) {
        roleManagementService.deleteRole(roleId);
        return ResponseEntity.noContent().build();
    }

    @DeleteMapping("/name/{roleName}")
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(
            summary = "根据角色名称删除角色记录",
            description = "管理员删除指定角色名称的角色记录，仅限 ADMIN 角色。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "204", description = "角色记录删除成功"),
            @ApiResponse(responseCode = "403", description = "无权限访问，仅限 ADMIN 角色"),
            @ApiResponse(responseCode = "404", description = "未找到角色记录"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<Void> deleteRoleByName(
            @PathVariable @Parameter(description = "角色名称", required = true) String roleName) {
        roleManagementService.deleteRoleByName(roleName);
        return ResponseEntity.noContent().build();
    }
}