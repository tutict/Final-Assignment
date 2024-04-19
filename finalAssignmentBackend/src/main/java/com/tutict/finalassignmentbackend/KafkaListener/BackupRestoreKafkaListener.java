package com.tutict.finalassignmentbackend.KafkaListener;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentbackend.entity.BackupRestore;
import com.tutict.finalassignmentbackend.service.BackupRestoreService;
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
        try {
            // 反序列化消息内容为BackupRestore对象
            BackupRestore backupRestore = deserializeMessage(message);

            // 根据业务逻辑处理备份创建
            backupRestoreService.createBackup(backupRestore);

            // 确认消息已被成功处理
            acknowledgment.acknowledge();
        } catch (Exception e) {
            // 记录异常信息，不确认消息，以便Kafka重新投递
            log.error("Error processing backup create message: {}", message, e);
        }
    }

    @KafkaListener(topics = "backup_update", groupId = "backup_listener_group")
    public void onBackupUpdateReceived(String message, Acknowledgment acknowledgment) {
        try {
            // 反序列化消息内容为BackupRestore对象
            BackupRestore backupRestore = deserializeMessage(message);

            // 根据业务逻辑处理备份更新
            backupRestoreService.updateBackup(backupRestore);

            // 确认消息已被成功处理
            acknowledgment.acknowledge();
        } catch (Exception e) {
            // 记录异常信息，不确认消息，以便Kafka重新投递
            log.error("Error processing backup update message: {}", message, e);
        }
    }

    private BackupRestore deserializeMessage(String message) throws JsonProcessingException {
        // 实现JSON字符串到BackupRestore对象的反序列化
        return objectMapper.readValue(message, BackupRestore.class);
    }
}