package com.tutict.finalassignmentbackend.KafkaListener;

import com.tutict.finalassignmentbackend.entity.BackupRestore;
import com.tutict.finalassignmentbackend.service.BackupRestoreService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.kafka.support.Acknowledgment;
import org.springframework.stereotype.Service;

@Service
public class BackupRestoreKafkaListener {

    private final BackupRestoreService backupRestoreService;

    @Autowired
    public BackupRestoreKafkaListener(BackupRestoreService backupRestoreService) {
        this.backupRestoreService = backupRestoreService;
    }

    @KafkaListener(topics = "backup_command_topic", groupId = "backup_group")
    public void onBackupCommandReceived(String message, Acknowledgment acknowledgment) {
        try {
            // 解析消息内容，确定备份操作的类型和参数
            // 例如，这里可以根据消息内容创建一个备份任务
            BackupRestore backup = parseBackupCommand(message);
            backupRestoreService.createBackup(backup);

            // 确认消息处理成功
            acknowledgment.acknowledge();
        } catch (Exception e) {
            // 处理异常，可以选择不确认消息，以便Kafka重新投递
            // acknowledgment.nack(false, false);
            // log.error("Error processing backup command", e);
        }
    }

    private BackupRestore parseBackupCommand(String message) {
        // 实现消息内容解析逻辑，创建BackupRestore对象
        // 这里只是一个示意，需要根据实际的消息格式来实现

        // 模拟返回一个BackupRestore对象
        return new BackupRestore();
    }
}
