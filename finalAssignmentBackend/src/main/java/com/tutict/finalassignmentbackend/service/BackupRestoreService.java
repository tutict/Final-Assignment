package com.tutict.finalassignmentbackend.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.tutict.finalassignmentbackend.dao.BackupRestoreMapper;
import com.tutict.finalassignmentbackend.entity.BackupRestore;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class BackupRestoreService {

    private final BackupRestoreMapper backupRestoreMapper;

    @Autowired
    public BackupRestoreService(BackupRestoreMapper backupRestoreMapper) {
        this.backupRestoreMapper = backupRestoreMapper;
    }

    public void createBackup(BackupRestore backup) {
        backupRestoreMapper.insert(backup);
    }

    public List<BackupRestore> getAllBackups() {
        return backupRestoreMapper.selectList(null);
    }

    public BackupRestore getBackupById(int backupId) {
        return backupRestoreMapper.selectById(backupId);
    }

    public void deleteBackup(int backupId) {
        backupRestoreMapper.deleteById(backupId);
    }

    public void updateBackup(BackupRestore backup) {
        backupRestoreMapper.updateById(backup);
    }

    public BackupRestore getupByFileName(String backupFileName) {
        QueryWrapper<BackupRestore> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("backupFileName", backupFileName);
        return backupRestoreMapper.selectOne(queryWrapper);
    }

    public List<BackupRestore> getBackupsByTime(String backupTime) {
        QueryWrapper<BackupRestore> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("backupTime", backupTime);
        return backupRestoreMapper.selectList(queryWrapper);
    }
}
