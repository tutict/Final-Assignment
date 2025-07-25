package com.tutict.finalassignmentbackend.controller;

import com.tutict.finalassignmentbackend.entity.BackupRestore;
import com.tutict.finalassignmentbackend.service.BackupRestoreService;
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
import java.util.logging.Logger;

@RestController
@RequestMapping("/api/backups")
@SecurityRequirement(name = "bearerAuth")
@Tag(name = "Backup and Restore", description = "APIs for managing backup and restore operations")
public class BackupRestoreController {

    private static final Logger logger = Logger.getLogger(BackupRestoreController.class.getName());

    private final BackupRestoreService backupRestoreService;

    public BackupRestoreController(BackupRestoreService backupRestoreService) {
        this.backupRestoreService = backupRestoreService;
    }

    @PostMapping
    @Transactional
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(
            summary = "创建备份记录",
            description = "管理员创建新的备份记录，需要提供幂等键以防止重复提交。操作在事务中执行。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "201", description = "备份记录创建成功"),
            @ApiResponse(responseCode = "400", description = "无效的输入参数或幂等键冲突"),
            @ApiResponse(responseCode = "403", description = "无权限访问，仅限 ADMIN 角色"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<Void> createBackup(
            @RequestBody @Parameter(description = "备份记录的详细信息", required = true) BackupRestore backup,
            @RequestParam @Parameter(description = "幂等键，用于防止重复提交", required = true) String idempotencyKey) {
        logger.info("Attempting to create backup with idempotency key: " + idempotencyKey);
        backupRestoreService.checkAndInsertIdempotency(idempotencyKey, backup, "create");
        logger.info("Backup created successfully.");
        return ResponseEntity.status(HttpStatus.CREATED).build();
    }

    @GetMapping
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    @Operation(
            summary = "获取所有备份记录",
            description = "获取所有备份记录的列表，USER 和 ADMIN 角色均可访问。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "成功返回备份记录列表"),
            @ApiResponse(responseCode = "403", description = "无权限访问，需 USER 或 ADMIN 角色"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<List<BackupRestore>> getAllBackups() {
        logger.info("Fetching all backups.");
        List<BackupRestore> backups = backupRestoreService.getAllBackups();
        logger.info("Total backups found: " + backups.size());
        return ResponseEntity.ok(backups);
    }

    @GetMapping("/{backupId}")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    @Operation(
            summary = "根据ID获取备份记录",
            description = "获取指定ID的备份记录，USER 和 ADMIN 角色均可访问。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "成功返回备份记录"),
            @ApiResponse(responseCode = "403", description = "无权限访问，需 USER 或 ADMIN 角色"),
            @ApiResponse(responseCode = "404", description = "未找到备份记录"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<BackupRestore> getBackupById(
            @PathVariable @Parameter(description = "备份记录ID", required = true) int backupId) {
        logger.info("Fetching backup by ID: " + backupId);
        BackupRestore backup = backupRestoreService.getBackupById(backupId);
        if (backup != null) {
            return ResponseEntity.ok(backup);
        } else {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
        }
    }

    @DeleteMapping("/{backupId}")
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(
            summary = "删除备份记录",
            description = "管理员删除指定ID的备份记录，仅限 ADMIN 角色。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "204", description = "备份记录删除成功"),
            @ApiResponse(responseCode = "403", description = "无权限访问，仅限 ADMIN 角色"),
            @ApiResponse(responseCode = "404", description = "未找到备份记录"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<Void> deleteBackup(
            @PathVariable @Parameter(description = "备份记录ID", required = true) int backupId) {
        logger.info("Attempting to delete backup with ID: " + backupId);
        backupRestoreService.deleteBackup(backupId);
        logger.info("Backup deleted successfully.");
        return ResponseEntity.noContent().build();
    }

    @PutMapping("/{backupId}")
    @Transactional
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(
            summary = "更新备份记录",
            description = "管理员更新指定ID的备份记录，需要提供幂等键以防止重复提交。操作在事务中执行。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "备份记录更新成功"),
            @ApiResponse(responseCode = "400", description = "无效的输入参数或幂等键冲突"),
            @ApiResponse(responseCode = "403", description = "无权限访问，仅限 ADMIN 角色"),
            @ApiResponse(responseCode = "404", description = "未找到备份记录"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<Void> updateBackup(
            @PathVariable @Parameter(description = "备份记录ID", required = true) int backupId,
            @RequestBody @Parameter(description = "更新后的备份记录信息", required = true) BackupRestore updatedBackup,
            @RequestParam @Parameter(description = "幂等键，用于防止重复提交", required = true) String idempotencyKey) {
        logger.info("Attempting to update backup with ID: " + backupId);
        BackupRestore existingBackup = backupRestoreService.getBackupById(backupId);
        if (existingBackup != null) {
            updatedBackup.setBackupId(backupId);
            backupRestoreService.checkAndInsertIdempotency(idempotencyKey, updatedBackup, "update");
            logger.info("Backup updated successfully.");
            return ResponseEntity.ok().build();
        } else {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
        }
    }

    @GetMapping("/filename/{backupFileName}")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    @Operation(
            summary = "根据文件名获取备份记录",
            description = "获取指定文件名的备份记录，USER 和 ADMIN 角色均可访问。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "成功返回备份记录"),
            @ApiResponse(responseCode = "403", description = "无权限访问，需 USER 或 ADMIN 角色"),
            @ApiResponse(responseCode = "404", description = "未找到备份记录"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<BackupRestore> getBackupByFileName(
            @PathVariable @Parameter(description = "备份文件名", required = true) String backupFileName) {
        logger.info("Fetching backup by file name: " + backupFileName);
        BackupRestore backup = backupRestoreService.getBackupByFileName(backupFileName);
        if (backup != null) {
            return ResponseEntity.ok(backup);
        } else {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
        }
    }

    @GetMapping("/time/{backupTime}")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    @Operation(
            summary = "根据备份时间获取备份记录",
            description = "获取指定备份时间的备份记录列表，USER 和 ADMIN 角色均可访问。备份时间格式为 yyyy-MM-dd'T'HH:mm:ss。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "成功返回备份记录列表"),
            @ApiResponse(responseCode = "400", description = "无效的备份时间格式"),
            @ApiResponse(responseCode = "403", description = "无权限访问，需 USER 或 ADMIN 角色"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<List<BackupRestore>> getBackupsByTime(
            @PathVariable @Parameter(description = "备份时间，格式：yyyy-MM-dd'T'HH:mm:ss", required = true) String backupTime) {
        logger.info("Fetching backups by time: " + backupTime);
        List<BackupRestore> backups = backupRestoreService.getBackupsByTime(backupTime);
        return ResponseEntity.ok(backups);
    }
}