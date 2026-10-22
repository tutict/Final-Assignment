package com.tutict.finalassignmentcloud.user.controller;

import com.tutict.finalassignmentcloud.config.security.InternalServiceTokenFilter;
import com.tutict.finalassignmentcloud.entity.SysRole;
import com.tutict.finalassignmentcloud.user.service.SysRoleService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.annotation.security.RolesAllowed;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * 内部服务间接口（service-to-service）：角色查询与创建。
 *
 * <p>登录与注册流程在拿到终端用户 JWT 之前就需要解析角色码，因此这些读取/写入走内部接口，
 * 由 {@link InternalServiceTokenFilter} 校验 {@code X-Internal-Service-Token}，
 * 并以内部服务身份（ROLE_INTERNAL）执行，不依赖管理员角色。
 */
@RestController
@RequestMapping("/api/roles/internal")
@RolesAllowed({InternalServiceTokenFilter.ROLE_INTERNAL})
@Tag(name = "Internal Role Management", description = "内部服务间角色查询接口（service-token 保护）")
public class InternalRoleManagementController {

    private static final Logger LOG = Logger.getLogger(InternalRoleManagementController.class.getName());

    private final SysRoleService sysRoleService;

    public InternalRoleManagementController(SysRoleService sysRoleService) {
        this.sysRoleService = sysRoleService;
    }

    @GetMapping("/{roleId}")
    @Operation(summary = "按角色 ID 查询角色（内部调用）")
    public ResponseEntity<SysRole> getById(@PathVariable Integer roleId) {
        try {
            SysRole role = sysRoleService.findById(roleId);
            return role == null ? ResponseEntity.notFound().build() : ResponseEntity.ok(role);
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Internal get role failed: " + roleId, ex);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    @GetMapping("/by-code/{roleCode}")
    @Operation(summary = "按角色编码查询角色（内部调用）")
    public ResponseEntity<SysRole> getByCode(@PathVariable String roleCode) {
        try {
            SysRole role = sysRoleService.findByRoleCode(roleCode);
            return role == null ? ResponseEntity.notFound().build() : ResponseEntity.ok(role);
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Internal get role by code failed: " + roleCode, ex);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    @PostMapping
    @Operation(summary = "创建角色（内部调用）")
    public ResponseEntity<SysRole> create(@RequestBody SysRole request) {
        try {
            return ResponseEntity.status(HttpStatus.CREATED).body(sysRoleService.createSysRole(request));
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Internal create role failed: " + request.getRoleCode(), ex);
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).build();
        }
    }
}
