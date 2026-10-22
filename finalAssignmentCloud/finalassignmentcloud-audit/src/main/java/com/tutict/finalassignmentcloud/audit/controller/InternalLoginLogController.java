package com.tutict.finalassignmentcloud.audit.controller;

import com.tutict.finalassignmentcloud.audit.service.AuditLoginLogService;
import com.tutict.finalassignmentcloud.config.security.InternalServiceTokenFilter;
import com.tutict.finalassignmentcloud.entity.AuditLoginLog;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.annotation.security.RolesAllowed;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * 内部服务间接口：写入登录审计日志。
 *
 * <p>登录成功/失败日志在认证完成前就要落库，此时没有终端用户 JWT，
 * 因此走内部接口，由 {@link InternalServiceTokenFilter} 校验内部令牌并以内部服务身份执行。
 */
@RestController
@RequestMapping("/api/logs/internal/login")
@RolesAllowed({InternalServiceTokenFilter.ROLE_INTERNAL})
@Tag(name = "Internal Login Audit", description = "内部服务间登录日志写入接口（service-token 保护）")
public class InternalLoginLogController {

    private static final Logger LOG = Logger.getLogger(InternalLoginLogController.class.getName());

    private final AuditLoginLogService auditLoginLogService;

    public InternalLoginLogController(AuditLoginLogService auditLoginLogService) {
        this.auditLoginLogService = auditLoginLogService;
    }

    @PostMapping
    @Operation(summary = "写入登录日志（内部调用）")
    public ResponseEntity<AuditLoginLog> create(@RequestBody AuditLoginLog request) {
        try {
            return ResponseEntity.status(HttpStatus.CREATED).body(auditLoginLogService.createAuditLoginLog(request));
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Internal create login log failed for username: " + request.getUsername(), ex);
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).build();
        }
    }
}
