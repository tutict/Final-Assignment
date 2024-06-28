package finalassignmentbackend.controller;

import com.tutict.finalassignmentbackend.entity.BackupRestore;
import com.tutict.finalassignmentbackend.service.BackupRestoreService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/eventbus/backups")
public class BackupRestoreController {

    private final BackupRestoreService backupRestoreService;

    @Autowired
    public BackupRestoreController(BackupRestoreService backupRestoreService) {
        this.backupRestoreService = backupRestoreService;
    }

    @PostMapping
    public ResponseEntity<Void> createBackup(@RequestBody BackupRestore backup) {
        backupRestoreService.createBackup(backup);
        return ResponseEntity.status(HttpStatus.CREATED).build();
    }

    @GetMapping
    public ResponseEntity<List<BackupRestore>> getAllBackups() {
        List<BackupRestore> backups = backupRestoreService.getAllBackups();
        return ResponseEntity.ok(backups);
    }

    @GetMapping("/{backupId}")
    public ResponseEntity<BackupRestore> getBackupById(@PathVariable int backupId) {
        BackupRestore backup = backupRestoreService.getBackupById(backupId);
        if (backup != null) {
            return ResponseEntity.ok(backup);
        } else {
            return ResponseEntity.notFound().build();
        }
    }

    @DeleteMapping("/{backupId}")
    public ResponseEntity<Void> deleteBackup(@PathVariable int backupId) {
        backupRestoreService.deleteBackup(backupId);
        return ResponseEntity.noContent().build();
    }

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

    @GetMapping("/filename/{backupFileName}")
    public ResponseEntity<BackupRestore> getBackupByFileName(@PathVariable String backupFileName) {
        BackupRestore backup = backupRestoreService.getupByFileName(backupFileName);
        if (backup != null) {
            return ResponseEntity.ok(backup);
        } else {
            return ResponseEntity.notFound().build();
        }
    }

    @GetMapping("/time/{backupTime}")
    public ResponseEntity<List<BackupRestore>> getBackupsByTime(@PathVariable String backupTime) {
        List<BackupRestore> backups = backupRestoreService.getBackupsByTime(backupTime);
        return ResponseEntity.ok(backups);
    }
}