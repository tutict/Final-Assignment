package com.tutict.finalassignmentbackend.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.tutict.finalassignmentbackend.config.websocket.WsAction;
import com.tutict.finalassignmentbackend.entity.RequestHistory;
import com.tutict.finalassignmentbackend.mapper.BackupRestoreMapper;
import com.tutict.finalassignmentbackend.entity.BackupRestore;
import com.tutict.finalassignmentbackend.mapper.RequestHistoryMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.kafka.annotation.EnableKafka;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.logging.Logger;

// 备份恢复服务类，处理备份创建、更新、查询和删除操作
@Service
@EnableKafka
public class BackupRestoreService {

    private static final Logger log = Logger.getLogger(BackupRestoreService.class.getName());

    private final BackupRestoreMapper backupRestoreMapper;
    private final RequestHistoryMapper requestHistoryMapper;
    private final KafkaTemplate<String, BackupRestore> kafkaTemplate;

    @Autowired
    public BackupRestoreService(BackupRestoreMapper backupRestoreMapper,
                                RequestHistoryMapper requestHistoryMapper,
                                KafkaTemplate<String, BackupRestore> kafkaTemplate) {
        this.backupRestoreMapper = backupRestoreMapper;
        this.requestHistoryMapper = requestHistoryMapper;
        this.kafkaTemplate = kafkaTemplate;
    }

    @Transactional
    @CacheEvict(cacheNames = "backupCache", allEntries = true)
    @WsAction(service = "BackupRestoreService", action = "checkAndInsertIdempotency")
    public void checkAndInsertIdempotency(String idempotencyKey, BackupRestore backupRestore, String action) {
        RequestHistory existingRequest = requestHistoryMapper.selectByIdempotencyKey(idempotencyKey);
        if (existingRequest != null) {
            log.warning(String.format("Duplicate request detected (idempotencyKey=%s)", idempotencyKey));
            throw new RuntimeException("Duplicate request detected");
        }

        RequestHistory newRequest = new RequestHistory();
        newRequest.setIdempotentKey(idempotencyKey);
        newRequest.setBusinessStatus("PROCESSING");

        try {
            requestHistoryMapper.insert(newRequest);
        } catch (Exception e) {
            log.severe("Failed to insert requestHistory for idempotencyKey=" + idempotencyKey + ", " + e.getMessage());
            throw new RuntimeException("Duplicate request or DB insert error", e);
        }

        sendKafkaMessage("backup_" + action, backupRestore);

        Integer backupId = backupRestore.getBackupId();
        newRequest.setBusinessStatus("SUCCESS");
        newRequest.setBusinessId(backupId != null ? backupId.longValue() : null);
        requestHistoryMapper.updateById(newRequest);
    }

    @Transactional
    @CacheEvict(cacheNames = "backupCache", allEntries = true)
    public void createBackup(BackupRestore backup) {
        BackupRestore existingBackup = backupRestoreMapper.selectById(backup.getBackupId());
        if (existingBackup == null) {
            backupRestoreMapper.insert(backup);
        } else {
            backupRestoreMapper.updateById(backup);
        }
    }

    @Transactional
    @CacheEvict(cacheNames = "backupCache", allEntries = true)
    public void updateBackup(BackupRestore backup) {
        BackupRestore existingBackup = backupRestoreMapper.selectById(backup.getBackupId());
        if (existingBackup == null) {
            backupRestoreMapper.insert(backup);
        } else {
            backupRestoreMapper.updateById(backup);
        }
    }

    @Transactional
    @CacheEvict(cacheNames = "backupCache", allEntries = true)
    @WsAction(service = "BackupRestoreService", action = "deleteBackup")
    public void deleteBackup(Integer backupId) {
        if (backupId == null || backupId <= 0) {
            throw new IllegalArgumentException("Invalid backup ID");
        }
        int result = backupRestoreMapper.deleteById(backupId);
        if (result > 0) {
            log.info(String.format("Backup with ID %s deleted successfully", backupId));
        } else {
            log.severe(String.format("Failed to delete backup with ID %s", backupId));
        }
    }

    @Cacheable(cacheNames = "backupCache")
    @WsAction(service = "BackupRestoreService", action = "getBackupById")
    public BackupRestore getBackupById(Integer backupId) {
        if (backupId == null || backupId <= 0 || backupId >= Integer.MAX_VALUE) {
            throw new IllegalArgumentException("Invalid backup ID " + backupId);
        }
        return backupRestoreMapper.selectById(backupId);
    }

    @Cacheable(cacheNames = "backupCache")
    @WsAction(service = "BackupRestoreService", action = "getAllBackups")
    public List<BackupRestore> getAllBackups() {
        return backupRestoreMapper.selectList(null);
    }

    @Cacheable(cacheNames = "backupCache")
    @WsAction(service = "BackupRestoreService", action = "getBackupByFileName")
    public BackupRestore getBackupByFileName(String backupFileName) {
        if (backupFileName == null || backupFileName.trim().isEmpty()) {
            throw new IllegalArgumentException("Invalid backup file name");
        }
        QueryWrapper<BackupRestore> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("backup_file_name", backupFileName);
        return backupRestoreMapper.selectOne(queryWrapper);
    }

    @Cacheable(cacheNames = "backupCache")
    @WsAction(service = "BackupRestoreService", action = "getBackupsByTime")
    public List<BackupRestore> getBackupsByTime(String backupTime) {
        if (backupTime == null || backupTime.trim().isEmpty()) {
            throw new IllegalArgumentException("Invalid backup time");
        }
        QueryWrapper<BackupRestore> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("backup_time", backupTime);
        return backupRestoreMapper.selectList(queryWrapper);
    }

    private void sendKafkaMessage(String topic, BackupRestore backup) {
        kafkaTemplate.send(topic, backup);
        log.info(String.format("Message sent to Kafka topic %s successfully", topic));
    }
}