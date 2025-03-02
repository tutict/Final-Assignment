package com.tutict.finalassignmentbackend.controller;

import com.tutict.finalassignmentbackend.entity.BackupRestore;
import com.tutict.finalassignmentbackend.service.BackupRestoreService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.scheduling.annotation.Async;
import org.springframework.web.bind.annotation.*;
import org.springframework.security.access.prepost.PreAuthorize;

import java.util.List;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.logging.Logger;

@RestController
@RequestMapping("/api/backups")
public class BackupRestoreController {

    private static final Logger logger = Logger.getLogger(BackupRestoreController.class.getName());

    private static final ExecutorService virtualThreadExecutor = Executors.newVirtualThreadPerTaskExecutor();

    private final BackupRestoreService backupRestoreService;

    public BackupRestoreController(BackupRestoreService backupRestoreService) {
        this.backupRestoreService = backupRestoreService;
    }

    // Create new backup record (仅 ADMIN)
    @PostMapping
    @Async
    @Transactional
    @PreAuthorize("hasRole('ADMIN')")
    public CompletableFuture<ResponseEntity<Void>> createBackup(@RequestBody BackupRestore backup, @RequestParam String idempotencyKey) {
        return CompletableFuture.supplyAsync(() -> {
            logger.info("Attempting to create backup with idempotency key: " + idempotencyKey);
            backupRestoreService.checkAndInsertIdempotency(idempotencyKey, backup, "create");
            logger.info("Backup created successfully.");
            return ResponseEntity.status(HttpStatus.CREATED).build();
        }, virtualThreadExecutor);
    }

    // Get all backups (USER 和 ADMIN)
    @GetMapping
    @Async
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public CompletableFuture<ResponseEntity<List<BackupRestore>>> getAllBackups() {
        return CompletableFuture.supplyAsync(() -> {
            logger.info("Fetching all backups.");
            List<BackupRestore> backups = backupRestoreService.getAllBackups();
            logger.info("Total backups found: " + backups.size());
            return ResponseEntity.ok(backups);
        }, virtualThreadExecutor);
    }

    // Get backup by ID (USER 和 ADMIN)
    @GetMapping("/{backupId}")
    @Async
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public CompletableFuture<ResponseEntity<BackupRestore>> getBackupById(@PathVariable int backupId) {
        return CompletableFuture.supplyAsync(() -> {
            logger.info("Fetching backup by ID: " + backupId);
            BackupRestore backup = backupRestoreService.getBackupById(backupId);
            if (backup != null) {
                return ResponseEntity.ok(backup);
            } else {
                return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
            }
        }, virtualThreadExecutor);
    }

    // Delete backup by ID (仅 ADMIN)
    @DeleteMapping("/{backupId}")
    @Async
    @PreAuthorize("hasRole('ADMIN')")
    public CompletableFuture<ResponseEntity<Void>> deleteBackup(@PathVariable int backupId) {
        return CompletableFuture.supplyAsync(() -> {
            logger.info("Attempting to delete backup with ID: " + backupId);
            backupRestoreService.deleteBackup(backupId);
            logger.info("Backup deleted successfully.");
            return ResponseEntity.noContent().build();
        }, virtualThreadExecutor);
    }

    // Update backup by ID (仅 ADMIN)
    @PutMapping("/{backupId}")
    @Async
    @Transactional
    @PreAuthorize("hasRole('ADMIN')")
    public CompletableFuture<ResponseEntity<Void>> updateBackup(@PathVariable int backupId, @RequestBody BackupRestore updatedBackup, @RequestParam String idempotencyKey) {
        return CompletableFuture.supplyAsync(() -> {
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
        }, virtualThreadExecutor);
    }

    // Get backup by file name (USER 和 ADMIN)
    @GetMapping("/filename/{backupFileName}")
    @Async
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public CompletableFuture<ResponseEntity<BackupRestore>> getBackupByFileName(@PathVariable String backupFileName) {
        return CompletableFuture.supplyAsync(() -> {
            logger.info("Fetching backup by file name: " + backupFileName);
            BackupRestore backup = backupRestoreService.getBackupByFileName(backupFileName);
            if (backup != null) {
                return ResponseEntity.ok(backup);
            } else {
                return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
            }
        }, virtualThreadExecutor);
    }

    // Get backups by backup time (USER 和 ADMIN)
    @GetMapping("/time/{backupTime}")
    @Async
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public CompletableFuture<ResponseEntity<List<BackupRestore>>> getBackupsByTime(@PathVariable String backupTime) {
        return CompletableFuture.supplyAsync(() -> {
            logger.info("Fetching backups by time: " + backupTime);
            List<BackupRestore> backups = backupRestoreService.getBackupsByTime(backupTime);
            return ResponseEntity.ok(backups);
        }, virtualThreadExecutor);
    }
}