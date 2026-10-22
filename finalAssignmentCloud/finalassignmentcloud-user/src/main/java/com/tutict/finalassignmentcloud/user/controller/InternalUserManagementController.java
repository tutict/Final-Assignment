package com.tutict.finalassignmentcloud.user.controller;

import com.tutict.finalassignmentcloud.dto.internal.InternalUserCreateRequest;
import com.tutict.finalassignmentcloud.dto.internal.InternalUserView;
import com.tutict.finalassignmentcloud.entity.SysUser;
import com.tutict.finalassignmentcloud.user.service.SysUserService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
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
 * 内部服务间接口（service-to-service）。
 *
 * <p>路径 {@code /api/users/internal/**} 在 Spring Security 层 permitAll，由
 * {@link com.tutict.finalassignmentcloud.config.security.InternalServiceTokenFilter}
 * 用 {@code X-Internal-Service-Token} 强校验。返回包含密码哈希的内部 DTO，
 * 供 auth-service 在登录时验密码——登录流程中用户尚无 JWT，不能走 JWT 保护的对外查询接口。
 */
@RestController
@RequestMapping("/api/users/internal")
@Tag(name = "Internal User Management", description = "内部服务间用户查询接口（service-token 保护）")
public class InternalUserManagementController {

    private static final Logger LOG = Logger.getLogger(InternalUserManagementController.class.getName());

    private final SysUserService sysUserService;

    public InternalUserManagementController(SysUserService sysUserService) {
        this.sysUserService = sysUserService;
    }

    @PostMapping
    @Operation(summary = "创建用户（内部调用，密码为已编码哈希）")
    public ResponseEntity<InternalUserView> create(@RequestBody InternalUserCreateRequest request) {
        try {
            SysUser saved = sysUserService.createSysUser(request.toEntity());
            return ResponseEntity.status(HttpStatus.CREATED).body(InternalUserView.fromEntity(saved));
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Internal create user failed: " + request.getUsername(), ex);
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).build();
        }
    }

    @GetMapping("/search/username/{username}")
    @Operation(summary = "按用户名查询完整用户实体（内部调用）")
    public ResponseEntity<InternalUserView> getByUsername(@PathVariable String username) {
        try {
            SysUser user = sysUserService.findByUsernameForAuthentication(username);
            return user == null
                    ? ResponseEntity.notFound().build()
                    : ResponseEntity.ok(InternalUserView.fromEntity(user));
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Internal get user by username failed: " + username, ex);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }
}
