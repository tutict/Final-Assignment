package com.tutict.finalassignmentbackend.controller;

import com.tutict.finalassignmentbackend.entity.PermissionManagement;
import com.tutict.finalassignmentbackend.service.PermissionManagementService;
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
@RequestMapping("/api/permissions")
@SecurityRequirement(name = "bearerAuth")
@Tag(name = "Permission Management", description = "APIs for managing permission records")
public class PermissionManagementController {

    private final PermissionManagementService permissionManagementService;

    public PermissionManagementController(PermissionManagementService permissionManagementService) {
        this.permissionManagementService = permissionManagementService;
    }

    @PostMapping
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(
            summary = "创建权限记录",
            description = "管理员创建新的权限记录，仅限 ADMIN 角色。需要提供幂等键以防止重复提交。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "201", description = "权限记录创建成功"),
            @ApiResponse(responseCode = "400", description = "无效的输入参数或幂等键冲突"),
            @ApiResponse(responseCode = "403", description = "无权限访问，仅限 ADMIN 角色"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<Void> createPermission(
            @RequestBody @Parameter(description = "权限记录的详细信息", required = true) PermissionManagement permission,
            @RequestParam @Parameter(description = "幂等键，用于防止重复提交", required = true) String idempotencyKey) {
        permissionManagementService.checkAndInsertIdempotency(idempotencyKey, permission, "create");
        return ResponseEntity.status(HttpStatus.CREATED).build();
    }

    @GetMapping("/{permissionId}")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    @Operation(
            summary = "根据ID获取权限记录",
            description = "获取指定ID的权限记录，USER 和 ADMIN 角色均可访问。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "成功返回权限记录"),
            @ApiResponse(responseCode = "403", description = "无权限访问，需 USER 或 ADMIN 角色"),
            @ApiResponse(responseCode = "404", description = "未找到权限记录"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<PermissionManagement> getPermissionById(
            @PathVariable @Parameter(description = "权限ID", required = true) int permissionId) {
        PermissionManagement permission = permissionManagementService.getPermissionById(permissionId);
        if (permission != null) {
            return ResponseEntity.ok(permission);
        } else {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
        }
    }

    @GetMapping
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    @Operation(
            summary = "获取所有权限记录",
            description = "获取所有权限记录的列表，USER 和 ADMIN 角色均可访问。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "成功返回权限记录列表"),
            @ApiResponse(responseCode = "403", description = "无权限访问，需 USER 或 ADMIN 角色"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<List<PermissionManagement>> getAllPermissions() {
        List<PermissionManagement> permissions = permissionManagementService.getAllPermissions();
        return ResponseEntity.ok(permissions);
    }

    @GetMapping("/name/{permissionName}")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    @Operation(
            summary = "根据权限名称获取权限记录",
            description = "获取指定权限名称的权限记录，USER 和 ADMIN 角色均可访问。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "成功返回权限记录"),
            @ApiResponse(responseCode = "403", description = "无权限访问，需 USER 或 ADMIN 角色"),
            @ApiResponse(responseCode = "404", description = "未找到权限记录"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<PermissionManagement> getPermissionByName(
            @PathVariable @Parameter(description = "权限名称", required = true) String permissionName) {
        PermissionManagement permission = permissionManagementService.getPermissionByName(permissionName);
        if (permission != null) {
            return ResponseEntity.ok(permission);
        } else {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
        }
    }

    @GetMapping("/search")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    @Operation(
            summary = "根据权限名称模糊搜索权限记录",
            description = "根据权限名称模糊匹配获取权限记录列表，USER 和 ADMIN 角色均可访问。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "成功返回权限记录列表"),
            @ApiResponse(responseCode = "403", description = "无权限访问，需 USER 或 ADMIN 角色"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<List<PermissionManagement>> getPermissionsByNameLike(
            @RequestParam @Parameter(description = "权限名称查询字符串", required = true) String name) {
        List<PermissionManagement> permissions = permissionManagementService.getPermissionsByNameLike(name);
        return ResponseEntity.ok(permissions);
    }

    @PutMapping("/{permissionId}")
    @Transactional
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(
            summary = "更新权限记录",
            description = "管理员更新指定ID的权限记录，需要提供幂等键以防止重复提交。操作在事务中执行。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "权限记录更新成功"),
            @ApiResponse(responseCode = "400", description = "无效的输入参数或幂等键冲突"),
            @ApiResponse(responseCode = "403", description = "无权限访问，仅限 ADMIN 角色"),
            @ApiResponse(responseCode = "404", description = "未找到权限记录"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<PermissionManagement> updatePermission(
            @PathVariable @Parameter(description = "权限ID", required = true) int permissionId,
            @RequestBody @Parameter(description = "更新后的权限记录信息", required = true) PermissionManagement updatedPermission,
            @RequestParam @Parameter(description = "幂等键，用于防止重复提交", required = true) String idempotencyKey) {
        PermissionManagement existingPermission = permissionManagementService.getPermissionById(permissionId);
        if (existingPermission != null) {
            updatedPermission.setPermissionId(permissionId);
            permissionManagementService.checkAndInsertIdempotency(idempotencyKey, updatedPermission, "update");
            return ResponseEntity.ok(updatedPermission);
        } else {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
        }
    }

    @DeleteMapping("/{permissionId}")
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(
            summary = "根据ID删除权限记录",
            description = "管理员删除指定ID的权限记录，仅限 ADMIN 角色。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "204", description = "权限记录删除成功"),
            @ApiResponse(responseCode = "403", description = "无权限访问，仅限 ADMIN 角色"),
            @ApiResponse(responseCode = "404", description = "未找到权限记录"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<Void> deletePermission(
            @PathVariable @Parameter(description = "权限ID", required = true) int permissionId) {
        permissionManagementService.deletePermission(permissionId);
        return ResponseEntity.noContent().build();
    }

    @DeleteMapping("/name/{permissionName}")
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(
            summary = "根据权限名称删除权限记录",
            description = "管理员删除指定权限名称的权限记录，仅限 ADMIN 角色。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "204", description = "权限记录删除成功"),
            @ApiResponse(responseCode = "403", description = "无权限访问，仅限 ADMIN 角色"),
            @ApiResponse(responseCode = "404", description = "未找到权限记录"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<Void> deletePermissionByName(
            @PathVariable @Parameter(description = "权限名称", required = true) String permissionName) {
        permissionManagementService.deletePermissionByName(permissionName);
        return ResponseEntity.noContent().build();
    }
}