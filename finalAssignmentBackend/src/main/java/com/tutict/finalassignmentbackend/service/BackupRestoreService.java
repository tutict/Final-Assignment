package com.tutict.finalassignmentbackend.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.tutict.finalassignmentbackend.mapper.BackupRestoreMapper;
import com.tutict.finalassignmentbackend.entity.BackupRestore;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.kafka.support.SendResult;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.concurrent.CompletableFuture;

@Service
public class BackupRestoreService {

    private static final Logger log = LoggerFactory.getLogger(BackupRestoreService.class);

    private final BackupRestoreMapper backupRestoreMapper;
    private final KafkaTemplate<String, BackupRestore> kafkaTemplate;

    @Autowired
    public BackupRestoreService(BackupRestoreMapper backupRestoreMapper, KafkaTemplate<String, BackupRestore> kafkaTemplate) {
        this.backupRestoreMapper = backupRestoreMapper;
        this.kafkaTemplate = kafkaTemplate;
    }

    @Transactional
    public void createBackup(BackupRestore backup) {
        try {
            // 异步发送消息到 Kafka，并处理发送结果
            CompletableFuture<SendResult<String, BackupRestore>> future = kafkaTemplate.send("backup_create", backup);

            // 处理发送成功的情况
            future.thenAccept(sendResult -> log.info("Create message sent to Kafka successfully: {}", sendResult.toString())).exceptionally(ex -> {
                // 处理发送失败的情况
                log.error("Failed to send message to Kafka, triggering transaction rollback", ex);
                // 抛出异常
                throw new RuntimeException("Kafka message send failure", ex);
            });

            // 由于是异步发送，不需要等待发送完成，Spring事务管理器将处理事务
            backupRestoreMapper.insert(backup);

        } catch (Exception e) {
            // 记录异常信息
            log.error("Exception occurred while updating appeal or sending Kafka message", e);
            // 异常将由Spring事务管理器处理，可能触发事务回滚
            throw e;
        }
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

    @Transactional
    public void updateBackup(BackupRestore backup) {
        try {
            // 异步发送消息到 Kafka，并处理发送结果
            CompletableFuture<SendResult<String, BackupRestore>> future =kafkaTemplate.send("backup_update", backup);

            // 处理发送成功的情况
            future.thenAccept(sendResult -> log.info("Update message sent to Kafka successfully: {}", sendResult.toString())).exceptionally(ex -> {
                // 处理发送失败的情况
                log.error("Failed to send message to Kafka, triggering transaction rollback", ex);
                // 抛出异常
                throw new RuntimeException("Kafka message send failure", ex);
            });

            // 由于是异步发送，不需要等待发送完成，Spring事务管理器将处理事务
            backupRestoreMapper.updateById(backup);

        } catch (Exception e) {
            // 记录异常信息
            log.error("Exception occurred while updating appeal or sending Kafka message", e);
            // 异常将由Spring事务管理器处理，可能触发事务回滚
            throw e;
        }
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
