package com.tutict.finalassignmentbackend.service;

import com.tutict.finalassignmentbackend.dao.BackupRestoreMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
public class BackupRestoreService {

    private final BackupRestoreMapper backupRestoreMapper;

    @Autowired
    public BackupRestoreService(BackupRestoreMapper backupRestoreMapper) {
        this.backupRestoreMapper = backupRestoreMapper;
    }

}
