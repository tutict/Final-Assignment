package com.tutict.finalassignmentbackend.KafkaListener;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentbackend.entity.BackupRestore;
import com.tutict.finalassignmentbackend.service.BackupRestoreService;
import io.vertx.core.Future;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.kafka.support.Acknowledgment;
import org.springframework.stereotype.Component;

@Component
public class BackupRestoreKafkaListener {

    private static final Logger log = LoggerFactory.getLogger(BackupRestoreKafkaListener.class);
    private final BackupRestoreService backupRestoreService;
    private final ObjectMapper objectMapper = new ObjectMapper();

    @Autowired
    public BackupRestoreKafkaListener(BackupRestoreService backupRestoreService) {
        this.backupRestoreService = backupRestoreService;
    }

    @KafkaListener(topics = "backup_create", groupId = "backup_listener_group")
    public void onBackupCreateReceived(String message, Acknowledgment acknowledgment) {
        Future.<Void>future(promise -> {
            try {
                BackupRestore backupRestore = deserializeMessage(message);
                backupRestoreService.createBackup(backupRestore);
                promise.complete();
            } catch (Exception e) {
                log.error("Error processing backup create message: {}", message, e);
                promise.fail(e);
            }
        }).onComplete(res -> {
            if (res.succeeded()) {
                acknowledgment.acknowledge();
            } else {
                log.error("Error processing backup create message: {}", message, res.cause());
            }
        });
    }

    @KafkaListener(topics = "backup_update", groupId = "backup_listener_group")
    public void onBackupUpdateReceived(String message, Acknowledgment acknowledgment) {
        Future.<Void>future(promise -> {
            try {
                BackupRestore backupRestore = deserializeMessage(message);
                backupRestoreService.updateBackup(backupRestore);
                promise.complete();
            } catch (Exception e) {
                log.error("Error processing backup update message: {}", message, e);
                promise.fail(e);
            }
        }).onComplete(res -> {
            if (res.succeeded()) {
                acknowledgment.acknowledge();
            } else {
                log.error("Error processing backup update message: {}", message, res.cause());
            }
        });
    }

    private BackupRestore deserializeMessage(String message) throws JsonProcessingException {
        return objectMapper.readValue(message, BackupRestore.class);
    }
}