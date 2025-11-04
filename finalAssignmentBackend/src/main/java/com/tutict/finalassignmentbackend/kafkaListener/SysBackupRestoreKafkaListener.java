package com.tutict.finalassignmentbackend.kafkaListener;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentbackend.entity.SysBackupRestore;
import com.tutict.finalassignmentbackend.mapper.SysBackupRestoreMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.kafka.annotation.EnableKafka;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Service;

import java.util.logging.Level;
import java.util.logging.Logger;

@Service
@EnableKafka
public class SysBackupRestoreKafkaListener {

    private static final Logger log = Logger.getLogger(SysBackupRestoreKafkaListener.class.getName());

    private final SysBackupRestoreMapper sysBackupRestoreMapper;
    private final ObjectMapper objectMapper;

    @Autowired
    public SysBackupRestoreKafkaListener(SysBackupRestoreMapper sysBackupRestoreMapper, ObjectMapper objectMapper) {
        this.sysBackupRestoreMapper = sysBackupRestoreMapper;
        this.objectMapper = objectMapper;
    }

    @KafkaListener(topics = "sys_backup_restore_create", groupId = "sysBackupRestoreGroup", concurrency = "3")
    public void onSysBackupRestoreCreateReceived(String message) {
        log.log(Level.INFO, "Received Kafka message for create: {0}", message);
        Thread.ofVirtual().start(() -> processMessage(message, "create"));
    }

    @KafkaListener(topics = "sys_backup_restore_update", groupId = "sysBackupRestoreGroup", concurrency = "3")
    public void onSysBackupRestoreUpdateReceived(String message) {
        log.log(Level.INFO, "Received Kafka message for update: {0}", message);
        Thread.ofVirtual().start(() -> processMessage(message, "update"));
    }

    private void processMessage(String message, String action) {
        try {
            SysBackupRestore entity = deserializeMessage(message);
            if ("create".equals(action)) {
                entity.setBackupId(null);
                sysBackupRestoreMapper.insert(entity);
            } else if ("update".equals(action)) {
                sysBackupRestoreMapper.updateById(entity);
            } else {
                log.log(Level.WARNING, "Unsupported action: {0}", action);
                return;
            }
            log.info(String.format("SysBackupRestore %s action processed successfully: %s", action, entity));
        } catch (Exception e) {
            log.log(Level.SEVERE, String.format("Error processing %s SysBackupRestore message: %s", action, message), e);
            throw new RuntimeException(String.format("Failed to process %s SysBackupRestore message", action), e);
        }
    }

    private SysBackupRestore deserializeMessage(String message) {
        try {
            return objectMapper.readValue(message, SysBackupRestore.class);
        } catch (Exception e) {
            log.log(Level.SEVERE, "Failed to deserialize message: {0}", message);
            throw new RuntimeException("Failed to deserialize message", e);
        }
    }
}
