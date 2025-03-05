package com.tutict.finalassignmentbackend.controller;

import com.tutict.finalassignmentbackend.entity.BackupRestore;
import com.tutict.finalassignmentbackend.service.BackupRestoreService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;
import org.springframework.security.access.prepost.PreAuthorize;

import java.util.List;
import java.util.logging.Logger;

@RestController
@RequestMapping("/api/backups")
public class BackupRestoreController {

    private static final Logger logger = Logger.getLogger(BackupRestoreController.class.getName());

    private final BackupRestoreService backupRestoreService;

    public BackupRestoreController(BackupRestoreService backupRestoreService) {
        this.backupRestoreService = backupRestoreService;
    }

    // Create new backup record (仅 ADMIN)
    @PostMapping
    @Transactional
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Void> createBackup(@RequestBody BackupRestore backup, @RequestParam String idempotencyKey) {
        logger.info("Attempting to create backup with idempotency key: " + idempotencyKey);
        backupRestoreService.checkAndInsertIdempotency(idempotencyKey, backup, "create");
        logger.info("Backup created successfully.");
        return ResponseEntity.status(HttpStatus.CREATED).build();
    }

    // Get all backups (USER 和 ADMIN)
    @GetMapping
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public ResponseEntity<List<BackupRestore>> getAllBackups() {
        logger.info("Fetching all backups.");
        List<BackupRestore> backups = backupRestoreService.getAllBackups();
        logger.info("Total backups found: " + backups.size());
        return ResponseEntity.ok(backups);
    }

    // Get backup by ID (USER 和 ADMIN)
    @GetMapping("/{backupId}")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public ResponseEntity<BackupRestore> getBackupById(@PathVariable int backupId) {
        logger.info("Fetching backup by ID: " + backupId);
        BackupRestore backup = backupRestoreService.getBackupById(backupId);
        if (backup != null) {
            return ResponseEntity.ok(backup);
        } else {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
        }
    }

    // Delete backup by ID (仅 ADMIN)
    @DeleteMapping("/{backupId}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Void> deleteBackup(@PathVariable int backupId) {
        logger.info("Attempting to delete backup with ID: " + backupId);
        backupRestoreService.deleteBackup(backupId);
        logger.info("Backup deleted successfully.");
        return ResponseEntity.noContent().build();
    }

    // Update backup by ID (仅 ADMIN)
    @PutMapping("/{backupId}")
    @Transactional
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Void> updateBackup(@PathVariable int backupId, @RequestBody BackupRestore updatedBackup, @RequestParam String idempotencyKey) {
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

    // Get backup by file name (USER 和 ADMIN)
    @GetMapping("/filename/{backupFileName}")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public ResponseEntity<BackupRestore> getBackupByFileName(@PathVariable String backupFileName) {
        logger.info("Fetching backup by file name: " + backupFileName);
        BackupRestore backup = backupRestoreService.getBackupByFileName(backupFileName);
        if (backup != null) {
            return ResponseEntity.ok(backup);
        } else {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
        }
    }

    // Get backups by backup time (USER 和 ADMIN)
    @GetMapping("/time/{backupTime}")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public ResponseEntity<List<BackupRestore>> getBackupsByTime(@PathVariable String backupTime) {
        logger.info("Fetching backups by time: " + backupTime);
        List<BackupRestore> backups = backupRestoreService.getBackupsByTime(backupTime);
        return ResponseEntity.ok(backups);
    }
}