package com.tutict.finalassignmentbackend.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.tutict.finalassignmentbackend.mapper.BackupRestoreMapper;
import com.tutict.finalassignmentbackend.entity.BackupRestore;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class BackupRestoreService {

    private final BackupRestoreMapper backupRestoreMapper;
    private final KafkaTemplate<String, BackupRestore> kafkaTemplate;

    @Autowired
    public BackupRestoreService(BackupRestoreMapper backupRestoreMapper, KafkaTemplate<String, BackupRestore> kafkaTemplate) {
        this.backupRestoreMapper = backupRestoreMapper;
        this.kafkaTemplate = kafkaTemplate;
    }

    public void createBackup(BackupRestore backup) {
        backupRestoreMapper.insert(backup);
        // 发送备份信息到 Kafka 主题
        kafkaTemplate.send("backup_topic", backup);
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
