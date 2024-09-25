package com.tutict.finalassignmentbackend.controller;

import com.tutict.finalassignmentbackend.entity.BackupRestore;
import com.tutict.finalassignmentbackend.service.BackupRestoreService;
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
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

// 控制器类，处理与事件总线备份相关的HTTP请求
@RestController
@RequestMapping("/eventbus/backups")
public class BackupRestoreController {

    // 备份恢复服务的依赖注入
    private final BackupRestoreService backupRestoreService;

    // 构造函数，通过依赖注入初始化备份恢复服务
    @Autowired
    public BackupRestoreController(BackupRestoreService backupRestoreService) {
        this.backupRestoreService = backupRestoreService;
    }

    // 创建一个新备份
    // 接受一个BackupRestore对象作为请求体，创建备份并返回201状态码
    @PostMapping
    public ResponseEntity<Void> createBackup(@RequestBody BackupRestore backup) {
        backupRestoreService.createBackup(backup);
        return ResponseEntity.status(HttpStatus.CREATED).build();
    }

    // 获取所有备份列表
    // 返回备份列表和200状态码
    @GetMapping
    public ResponseEntity<List<BackupRestore>> getAllBackups() {
        List<BackupRestore> backups = backupRestoreService.getAllBackups();
        return ResponseEntity.ok(backups);
    }

    // 根据ID获取备份
    // 如果找到对应ID的备份，返回该备份和200状态码；否则返回404状态码
    @GetMapping("/{backupId}")
    public ResponseEntity<BackupRestore> getBackupById(@PathVariable int backupId) {
        BackupRestore backup = backupRestoreService.getBackupById(backupId);
        if (backup != null) {
            return ResponseEntity.ok(backup);
        } else {
            return ResponseEntity.notFound().build();
        }
    }

    // 删除指定ID的备份
    // 删除备份后返回204状态码
    @DeleteMapping("/{backupId}")
    public ResponseEntity<Void> deleteBackup(@PathVariable int backupId) {
        backupRestoreService.deleteBackup(backupId);
        return ResponseEntity.noContent().build();
    }

    // 更新指定ID的备份
    // 如果找到对应ID的备份，更新备份信息并返回200状态码；否则返回404状态码
    @PutMapping("/{backupId}")
    public ResponseEntity<Void> updateBackup(@PathVariable int backupId, @RequestBody BackupRestore updatedBackup) {
        BackupRestore existingBackup = backupRestoreService.getBackupById(backupId);
        if (existingBackup != null) {
            updatedBackup.setBackupId(backupId);
            backupRestoreService.updateBackup(updatedBackup);
            return ResponseEntity.ok().build();
        } else {
            return ResponseEntity.notFound().build();
        }
    }

    // 根据文件名获取备份
    // 如果找到对应文件名的备份，返回该备份和200状态码；否则返回404状态码
    @GetMapping("/filename/{backupFileName}")
    public ResponseEntity<BackupRestore> getBackupByFileName(@PathVariable String backupFileName) {
        BackupRestore backup = backupRestoreService.getupByFileName(backupFileName);
        if (backup != null) {
            return ResponseEntity.ok(backup);
        } else {
            return ResponseEntity.notFound().build();
        }
    }

    // 根据备份时间获取备份列表
    // 返回匹配指定时间的备份列表和200状态码
    @GetMapping("/time/{backupTime}")
    public ResponseEntity<List<BackupRestore>> getBackupsByTime(@PathVariable String backupTime) {
        List<BackupRestore> backups = backupRestoreService.getBackupsByTime(backupTime);
        return ResponseEntity.ok(backups);
    }
}
