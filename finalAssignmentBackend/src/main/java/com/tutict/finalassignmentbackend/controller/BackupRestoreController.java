package com.tutict.finalassignmentbackend.controller;

import com.tutict.finalassignmentbackend.service.BackupRestoreService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/backup")
public class BackupRestoreController {

    private final BackupRestoreService backupRestoreService;

    @Autowired
    public BackupRestoreController(BackupRestoreService backupRestoreService) {
        this.backupRestoreService = backupRestoreService;
    }
}
