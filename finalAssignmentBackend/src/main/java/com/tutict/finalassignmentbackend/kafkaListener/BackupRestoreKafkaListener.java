package com.tutict.finalassignmentbackend.kafkaListener;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentbackend.entity.BackupRestore;
import com.tutict.finalassignmentbackend.service.BackupRestoreService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.kafka.annotation.EnableKafka;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.logging.Level;
import java.util.logging.Logger;

// 定义一个Kafka监听器类，用于处理备份和恢复相关操作
@Service
@EnableKafka
public class BackupRestoreKafkaListener {

    private static final Logger log = Logger.getLogger(BackupRestoreKafkaListener.class.getName());

    private final BackupRestoreService backupRestoreService;
    private final ObjectMapper objectMapper;

    @Autowired
    public BackupRestoreKafkaListener(BackupRestoreService backupRestoreService, ObjectMapper objectMapper) {
        this.backupRestoreService = backupRestoreService;
        this.objectMapper = objectMapper;
    }

    @KafkaListener(topics = "backup_create", groupId = "backupRestoreGroup")
    @Transactional
    public void onBackupCreateReceived(String message) {
        processMessage(message, "create", backupRestoreService::createBackup);
    }

    @KafkaListener(topics = "backup_update", groupId = "backupRestoreGroup")
    @Transactional
    public void onBackupUpdateReceived(String message) {
        processMessage(message, "update", backupRestoreService::updateBackup);
    }

    private void processMessage(String message, String action, MessageProcessor<BackupRestore> processor) {
        try {
            BackupRestore backupRestore = deserializeMessage(message);
            if ("create".equals(action)) {
                backupRestore.setBackupId(null);
                processor.process(backupRestore);
            }
            log.info(String.format("Backup %s action processed successfully: %s", action, message));
        } catch (Exception e) {
            log.log(Level.SEVERE, String.format("Error processing %s backup message: %s", action, message), e);
            throw new RuntimeException(String.format("Failed to process %s backup message", action), e);
        }
    }

    private BackupRestore deserializeMessage(String message) {
        try {
            return objectMapper.readValue(message, BackupRestore.class);
        } catch (Exception e) {
            log.log(Level.SEVERE, "Failed to deserialize message: " + message, e);
            throw new RuntimeException("Failed to deserialize message", e);
        }
    }

    @FunctionalInterface
    private interface MessageProcessor<T> {
        void process(T t) throws Exception;
    }
}