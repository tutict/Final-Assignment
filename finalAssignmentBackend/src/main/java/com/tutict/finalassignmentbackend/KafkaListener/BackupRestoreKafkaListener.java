package com.tutict.finalassignmentbackend.KafkaListener;

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

// 定义一个Kafka监听器类，用于处理备份和恢复相关操作
@Component
public class BackupRestoreKafkaListener {

    // 初始化日志记录器
    private static final Logger log = LoggerFactory.getLogger(BackupRestoreKafkaListener.class);
    // 注入备份恢复服务
    private final BackupRestoreService backupRestoreService;
    // 初始化对象映射器，用于JSON序列化和反序列化
    private final ObjectMapper objectMapper = new ObjectMapper().findAndRegisterModules();

    // 构造函数，接收一个BackupRestoreService实例
    @Autowired
    public BackupRestoreKafkaListener(BackupRestoreService backupRestoreService) {
        this.backupRestoreService = backupRestoreService;
    }

    // 监听"backup_create"主题，当收到消息时调用该方法处理
    @KafkaListener(topics = "backup_create", groupId = "backup_listener_group", concurrency = "3")
    public void onBackupCreateReceived(String message, Acknowledgment acknowledgment) {
        // 异步处理备份创建任务
        Future.<Void>future(promise -> {
            try {
                // 反序列化Kafka消息为BackupRestore对象
                BackupRestore backupRestore = deserializeMessage(message);
                // 调用服务创建备份
                backupRestoreService.createBackup(backupRestore);
                // 完成Promise，表示处理成功
                promise.complete();
            } catch (Exception e) {
                // 记录错误日志并失败Promise
                log.error("Error processing backup create message: {}", message, e);
                promise.fail(e);
            }
        }).onComplete(res -> {
            // 根据处理结果进行相应操作
            if (res.succeeded()) {
                // 如果处理成功，确认消息处理完成
                acknowledgment.acknowledge();
            } else {
                // 如果处理失败，记录错误日志
                log.error("Error processing backup create message: {}", message, res.cause());
            }
        });
    }

    // 监听"backup_update"主题，当收到消息时调用该方法处理
    @KafkaListener(topics = "backup_update", groupId = "backup_listener_group", concurrency = "3")
    public void onBackupUpdateReceived(String message, Acknowledgment acknowledgment) {
        // 异步处理备份更新任务
        Future.<Void>future(promise -> {
            try {
                // 反序列化Kafka消息为BackupRestore对象
                BackupRestore backupRestore = deserializeMessage(message);
                // 调用服务更新备份
                backupRestoreService.updateBackup(backupRestore);
                // 完成Promise，表示处理成功
                promise.complete();
            } catch (Exception e) {
                // 记录错误日志并失败Promise
                log.error("Error processing backup update message: {}", message, e);
                promise.fail(e);
            }
        }).onComplete(res -> {
            // 根据处理结果进行相应操作
            if (res.succeeded()) {
                // 如果处理成功，确认消息处理完成
                acknowledgment.acknowledge();
            } else {
                // 如果处理失败，记录错误日志
                log.error("Error processing backup update message: {}", message, res.cause());
            }
        });
    }

    // 将JSON字符串反序列化为BackupRestore对象
    private BackupRestore deserializeMessage(String message) {
        try {
            // 使用ObjectMapper反序列化JSON字符串
            return objectMapper.readValue(message, BackupRestore.class);
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
    }
}
