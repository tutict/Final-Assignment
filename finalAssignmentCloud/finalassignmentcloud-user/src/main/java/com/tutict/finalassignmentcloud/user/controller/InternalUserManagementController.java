package com.tutict.finalassignmentcloud.user.controller;

import com.tutict.finalassignmentcloud.config.security.InternalServiceTokenFilter;
import com.tutict.finalassignmentcloud.dto.internal.InternalUserCreateRequest;
import com.tutict.finalassignmentcloud.dto.internal.InternalUserProfile;
import com.tutict.finalassignmentcloud.dto.internal.InternalUserView;
import com.tutict.finalassignmentcloud.entity.SysUser;
import com.tutict.finalassignmentcloud.entity.SysUserRole;
import com.tutict.finalassignmentcloud.user.service.SysUserRoleService;
import com.tutict.finalassignmentcloud.user.service.SysUserService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.annotation.security.RolesAllowed;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * 内部服务间接口（service-to-service）。
 *
 * <p>路径 {@code /api/users/internal/**} 由
 * {@link InternalServiceTokenFilter} 用 {@code X-Internal-Service-Token} 强校验，
 * 并以内部服务身份（ROLE_INTERNAL）执行，不复用面向终端用户的角色与归属判定。
 *
 * <p>只有确实需要校验密码的认证流程才调用 {@code /authentication/username/{username}}，
 * 其余服务间读取一律使用不含密码哈希的 {@link InternalUserProfile}。
 */
@RestController
@RequestMapping("/api/users/internal")
@RolesAllowed({InternalServiceTokenFilter.ROLE_INTERNAL})
@Tag(name = "Internal User Management", description = "内部服务间用户查询接口（service-token 保护）")
public class InternalUserManagementController {

    private static final Logger LOG = Logger.getLogger(InternalUserManagementController.class.getName());
    private static final int MAX_ROLE_PAGE_SIZE = 100;

    private final SysUserService sysUserService;
    private final SysUserRoleService sysUserRoleService;

    public InternalUserManagementController(SysUserService sysUserService,
                                             SysUserRoleService sysUserRoleService) {
        this.sysUserService = sysUserService;
        this.sysUserRoleService = sysUserRoleService;
    }

    @PostMapping
    @Operation(summary = "创建用户（内部调用，密码为已编码哈希）")
    public ResponseEntity<InternalUserProfile> create(@RequestBody InternalUserCreateRequest request) {
        try {
            SysUser saved = sysUserService.createSysUser(request.toEntity());
            return ResponseEntity.status(HttpStatus.CREATED).body(InternalUserProfile.fromEntity(saved));
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Internal create user failed: " + request.getUsername(), ex);
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).build();
        }
    }

    @GetMapping("/authentication/username/{username}")
    @Operation(summary = "按用户名查询含密码哈希的用户（内部调用，仅用于密码校验）")
    public ResponseEntity<InternalUserView> getAuthenticationView(@PathVariable String username) {
        try {
            SysUser user = sysUserService.findByUsernameForAuthentication(username);
            return user == null
                    ? ResponseEntity.notFound().build()
                    : ResponseEntity.ok(InternalUserView.fromEntity(user));
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Internal get authentication view failed: " + username, ex);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    @GetMapping("/profile/username/{username}")
    @Operation(summary = "按用户名查询用户档案（内部调用，不含密码哈希）")
    public ResponseEntity<InternalUserProfile> getProfileByUsername(@PathVariable String username) {
        try {
            SysUser user = sysUserService.findByUsername(username);
            return user == null
                    ? ResponseEntity.notFound().build()
                    : ResponseEntity.ok(InternalUserProfile.fromEntity(user));
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Internal get profile by username failed: " + username, ex);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    @GetMapping("/{userId}")
    @Operation(summary = "按用户 ID 查询用户档案（内部调用，不含密码哈希）")
    public ResponseEntity<InternalUserProfile> getById(@PathVariable Long userId) {
        try {
            SysUser user = sysUserService.findById(userId);
            return user == null
                    ? ResponseEntity.notFound().build()
                    : ResponseEntity.ok(InternalUserProfile.fromEntity(user));
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Internal get user by id failed: " + userId, ex);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    @PutMapping("/{userId}")
    @Operation(summary = "按用户 ID 更新用户（内部调用）")
    public ResponseEntity<InternalUserProfile> update(@PathVariable Long userId, @RequestBody SysUser request) {
        try {
            request.setUserId(userId);
            SysUser updated = sysUserService.updateSysUser(request);
            return ResponseEntity.ok(InternalUserProfile.fromEntity(updated));
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Internal update user failed: " + userId, ex);
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).build();
        }
    }

    @GetMapping("/{userId}/roles")
    @Operation(summary = "查询用户角色列表（内部调用）")
    public ResponseEntity<List<SysUserRole>> listUserRoles(@PathVariable Long userId) {
        try {
            return ResponseEntity.ok(sysUserRoleService.findByUserId(userId, 1, MAX_ROLE_PAGE_SIZE));
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Internal list user roles failed: " + userId, ex);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    @PostMapping("/{userId}/roles")
    @Operation(summary = "绑定用户角色（内部调用）")
    public ResponseEntity<SysUserRole> addUserRole(@PathVariable Long userId, @RequestBody SysUserRole relation) {
        try {
            relation.setUserId(userId);
            SysUserRole saved = sysUserRoleService.createRelation(relation);
            return ResponseEntity.status(HttpStatus.CREATED).body(saved);
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Internal add user role failed: " + userId, ex);
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).build();
        }
    }
}
