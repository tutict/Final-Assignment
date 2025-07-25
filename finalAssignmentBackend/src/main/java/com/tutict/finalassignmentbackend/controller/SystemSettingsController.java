package com.tutict.finalassignmentbackend.controller;

import com.tutict.finalassignmentbackend.entity.SystemSettings;
import com.tutict.finalassignmentbackend.service.SystemSettingsService;
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

@RestController
@RequestMapping("/api/systemSettings")
@SecurityRequirement(name = "bearerAuth")
@Tag(name = "System Settings", description = "APIs for managing system settings")
public class SystemSettingsController {

    private final SystemSettingsService systemSettingsService;

    public SystemSettingsController(SystemSettingsService systemSettingsService) {
        this.systemSettingsService = systemSettingsService;
    }

    @GetMapping
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    @Operation(
            summary = "获取系统设置",
            description = "获取完整的系统设置信息，USER 和 ADMIN 角色均可访问。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "成功返回系统设置信息"),
            @ApiResponse(responseCode = "403", description = "无权限访问，需 USER 或 ADMIN 角色"),
            @ApiResponse(responseCode = "404", description = "未找到系统设置信息"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<SystemSettings> getSystemSettings() {
        SystemSettings systemSettings = systemSettingsService.getSystemSettings();
        if (systemSettings != null) {
            return ResponseEntity.ok(systemSettings);
        } else {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
        }
    }

    @PutMapping
    @Transactional
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(
            summary = "更新系统设置",
            description = "管理员更新系统设置信息，需要提供幂等键以防止重复提交。操作在事务中执行，仅限 ADMIN 角色。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "系统设置更新成功"),
            @ApiResponse(responseCode = "400", description = "无效的输入参数或幂等键冲突"),
            @ApiResponse(responseCode = "403", description = "无权限访问，仅限 ADMIN 角色"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<SystemSettings> updateSystemSettings(
            @RequestBody @Parameter(description = "更新后的系统设置信息", required = true) SystemSettings systemSettings,
            @RequestParam @Parameter(description = "幂等键，用于防止重复提交", required = true) String idempotencyKey) {
        systemSettingsService.checkAndInsertIdempotency(idempotencyKey, systemSettings);
        return ResponseEntity.ok(systemSettings);
    }

    @GetMapping("/systemName")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    @Operation(
            summary = "获取系统名称",
            description = "获取系统名称，USER 和 ADMIN 角色均可访问。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "成功返回系统名称"),
            @ApiResponse(responseCode = "403", description = "无权限访问，需 USER 或 ADMIN 角色"),
            @ApiResponse(responseCode = "404", description = "未找到系统名称"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<String> getSystemName() {
        String systemName = systemSettingsService.getSystemName();
        if (systemName != null) {
            return ResponseEntity.ok(systemName);
        } else {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
        }
    }

    @GetMapping("/systemVersion")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    @Operation(
            summary = "获取系统版本",
            description = "获取系统版本，USER 和 ADMIN 角色均可访问。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "成功返回系统版本"),
            @ApiResponse(responseCode = "403", description = "无权限访问，需 USER 或 ADMIN 角色"),
            @ApiResponse(responseCode = "404", description = "未找到系统版本"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<String> getSystemVersion() {
        String systemVersion = systemSettingsService.getSystemVersion();
        if (systemVersion != null) {
            return ResponseEntity.ok(systemVersion);
        } else {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
        }
    }

    @GetMapping("/systemDescription")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    @Operation(
            summary = "获取系统描述",
            description = "获取系统描述，USER 和 ADMIN 角色均可访问。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "成功返回系统描述"),
            @ApiResponse(responseCode = "403", description = "无权限访问，需 USER 或 ADMIN 角色"),
            @ApiResponse(responseCode = "404", description = "未找到系统描述"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<String> getSystemDescription() {
        String systemDescription = systemSettingsService.getSystemDescription();
        if (systemDescription != null) {
            return ResponseEntity.ok(systemDescription);
        } else {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
        }
    }

    @GetMapping("/copyrightInfo")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    @Operation(
            summary = "获取版权信息",
            description = "获取系统版权信息，USER 和 ADMIN 角色均可访问。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "成功返回版权信息"),
            @ApiResponse(responseCode = "403", description = "无权限访问，需 USER 或 ADMIN 角色"),
            @ApiResponse(responseCode = "404", description = "未找到版权信息"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<String> getCopyrightInfo() {
        String copyrightInfo = systemSettingsService.getCopyrightInfo();
        if (copyrightInfo != null) {
            return ResponseEntity.ok(copyrightInfo);
        } else {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
        }
    }

    @GetMapping("/storagePath")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    @Operation(
            summary = "获取存储路径",
            description = "获取系统存储路径，USER 和 ADMIN 角色均可访问。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "成功返回存储路径"),
            @ApiResponse(responseCode = "403", description = "无权限访问，需 USER 或 ADMIN 角色"),
            @ApiResponse(responseCode = "404", description = "未找到存储路径"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<String> getStoragePath() {
        String storagePath = systemSettingsService.getStoragePath();
        if (storagePath != null) {
            return ResponseEntity.ok(storagePath);
        } else {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
        }
    }

    @GetMapping("/loginTimeout")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    @Operation(
            summary = "获取登录超时时间",
            description = "获取系统登录超时时间（以秒为单位），USER 和 ADMIN 角色均可访问。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "成功返回登录超时时间"),
            @ApiResponse(responseCode = "403", description = "无权限访问，需 USER 或 ADMIN 角色"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<Integer> getLoginTimeout() {
        int loginTimeout = systemSettingsService.getLoginTimeout();
        return ResponseEntity.ok(loginTimeout);
    }

    @GetMapping("/sessionTimeout")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    @Operation(
            summary = "获取会话超时时间",
            description = "获取系统会话超时时间（以秒为单位），USER 和 ADMIN 角色均可访问。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "成功返回会话超时时间"),
            @ApiResponse(responseCode = "403", description = "无权限访问，需 USER 或 ADMIN 角色"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<Integer> getSessionTimeout() {
        int sessionTimeout = systemSettingsService.getSessionTimeout();
        return ResponseEntity.ok(sessionTimeout);
    }

    @GetMapping("/dateFormat")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    @Operation(
            summary = "获取日期格式",
            description = "获取系统日期格式，USER 和 ADMIN 角色均可访问。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "成功返回日期格式"),
            @ApiResponse(responseCode = "403", description = "无权限访问，需 USER 或 ADMIN 角色"),
            @ApiResponse(responseCode = "404", description = "未找到日期格式"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<String> getDateFormat() {
        String dateFormat = systemSettingsService.getDateFormat();
        if (dateFormat != null) {
            return ResponseEntity.ok(dateFormat);
        } else {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
        }
    }

    @GetMapping("/pageSize")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    @Operation(
            summary = "获取分页大小",
            description = "获取系统分页大小（每页记录数），USER 和 ADMIN 角色均可访问。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "成功返回分页大小"),
            @ApiResponse(responseCode = "403", description = "无权限访问，需 USER 或 ADMIN 角色"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<Integer> getPageSize() {
        int pageSize = systemSettingsService.getPageSize();
        return ResponseEntity.ok(pageSize);
    }

    @GetMapping("/smtpServer")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    @Operation(
            summary = "获取SMTP服务器",
            description = "获取系统SMTP服务器地址，USER 和 ADMIN 角色均可访问。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "成功返回SMTP服务器地址"),
            @ApiResponse(responseCode = "403", description = "无权限访问，需 USER 或 ADMIN 角色"),
            @ApiResponse(responseCode = "404", description = "未找到SMTP服务器地址"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<String> getSmtpServer() {
        String smtpServer = systemSettingsService.getSmtpServer();
        if (smtpServer != null) {
            return ResponseEntity.ok(smtpServer);
        } else {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
        }
    }

    @GetMapping("/emailAccount")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    @Operation(
            summary = "获取邮件账户",
            description = "获取系统邮件账户，USER 和 ADMIN 角色均可访问。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "成功返回邮件账户"),
            @ApiResponse(responseCode = "403", description = "无权限访问，需 USER 或 ADMIN 角色"),
            @ApiResponse(responseCode = "404", description = "未找到邮件账户"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<String> getEmailAccount() {
        String emailAccount = systemSettingsService.getEmailAccount();
        if (emailAccount != null) {
            return ResponseEntity.ok(emailAccount);
        } else {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
        }
    }

    @GetMapping("/emailPassword")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    @Operation(
            summary = "获取邮件密码",
            description = "获取系统邮件密码，USER 和 ADMIN 角色均可访问。注意：出于安全考虑，建议限制此端点的访问或加密返回数据。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "成功返回邮件密码"),
            @ApiResponse(responseCode = "403", description = "无权限访问，需 USER 或 ADMIN 角色"),
            @ApiResponse(responseCode = "404", description = "未找到邮件密码"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<String> getEmailPassword() {
        String emailPassword = systemSettingsService.getEmailPassword();
        if (emailPassword != null) {
            return ResponseEntity.ok(emailPassword);
        } else {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
        }
    }
}