package finalassignmentbackend.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import finalassignmentbackend.entity.BackupRestore;
import finalassignmentbackend.mapper.BackupRestoreMapper;
import io.quarkus.cache.CacheInvalidate;
import io.quarkus.cache.CacheResult;
import io.smallrye.mutiny.Uni;
import io.smallrye.reactive.messaging.MutinyEmitter;
import io.smallrye.reactive.messaging.kafka.api.OutgoingKafkaRecordMetadata;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.transaction.Transactional;
import org.eclipse.microprofile.reactive.messaging.Channel;
import org.eclipse.microprofile.reactive.messaging.Message;

import java.util.List;
import java.util.concurrent.CompletionStage;
import java.util.logging.Logger;

@ApplicationScoped
public class BackupRestoreService {

    private static final Logger log = Logger.getLogger(BackupRestoreService.class.getName());

    @Inject
    BackupRestoreMapper backupRestoreMapper;

    @Inject
    @Channel("backup-events-out")
    MutinyEmitter<BackupRestore> backupEmitter;

    @Transactional
    @CacheInvalidate(cacheName = "backupCache")
    public void createBackup(BackupRestore backup) {
        try {
            sendKafkaMessage("backup_create", backup);
            backupRestoreMapper.insert(backup);
        } catch (Exception e) {
            log.warning("Exception occurred while creating backup or sending Kafka message");
            throw new RuntimeException("Failed to create backup", e);
        }
    }

    @CacheResult(cacheName = "backupCache")
    public List<BackupRestore> getAllBackups() {
        return backupRestoreMapper.selectList(null);
    }

    @CacheResult(cacheName = "backupCache")
    public BackupRestore getBackupById(Integer backupId) {
        if (backupId == null || backupId <= 0) {
            throw new IllegalArgumentException("Invalid backup ID");
        }
        return backupRestoreMapper.selectById(backupId);
    }

    @Transactional
    @CacheInvalidate(cacheName = "backupCache")
    public void deleteBackup(Integer backupId) {
        try {
            int result = backupRestoreMapper.deleteById(backupId);
            if (result > 0) {
                log.info(String.format("Backup with ID %s deleted successfully", backupId));
            } else {
                log.severe(String.format("Failed to delete backup with ID %s", backupId));
            }
        } catch (Exception e) {
            log.warning("Exception occurred while deleting backup");
            throw new RuntimeException("Failed to delete backup", e);
        }
    }

    @Transactional
    @CacheInvalidate(cacheName = "backupCache")
    public void updateBackup(BackupRestore backup) {
        try {
            sendKafkaMessage("backup_update", backup);
            backupRestoreMapper.updateById(backup);
        } catch (Exception e) {
            log.warning("Exception occurred while updating backup or sending Kafka message");
            throw new RuntimeException("Failed to update backup", e);
        }
    }

    @CacheResult(cacheName = "backupCache")
    public BackupRestore getBackupByFileName(String backupFileName) {
        if (backupFileName == null || backupFileName.trim().isEmpty()) {
            throw new IllegalArgumentException("Invalid backup file name");
        }
        QueryWrapper<BackupRestore> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("backupFileName", backupFileName);
        return backupRestoreMapper.selectOne(queryWrapper);
    }

    @CacheResult(cacheName = "backupCache")
    public List<BackupRestore> getBackupsByTime(String backupTime) {
        if (backupTime == null || backupTime.trim().isEmpty()) {
            throw new IllegalArgumentException("Invalid backup time");
        }
        QueryWrapper<BackupRestore> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("backupTime", backupTime);
        return backupRestoreMapper.selectList(queryWrapper);
    }

    private void sendKafkaMessage(String topic, BackupRestore backup) {
        // 创建包含目标主题的元数据
        OutgoingKafkaRecordMetadata<String> metadata = OutgoingKafkaRecordMetadata.<String>builder()
                .withTopic(topic)
                .build();

        // 创建包含负载和元数据的消息
        Message<BackupRestore> message = Message.of(backup).addMetadata(metadata);

        // 使用 MutinyEmitter 的 sendMessage 方法返回 Uni<Void>
        Uni<Void> uni = backupEmitter.sendMessage(message);

        // 将 Uni<Void> 转换为 CompletionStage<Void>
        CompletionStage<Void> sendStage = uni.subscribe().asCompletionStage();

        sendStage.whenComplete((ignored, throwable) -> {
            if (throwable != null) {
                log.severe(String.format("Failed to send message to Kafka topic %s: %s", topic, throwable.getMessage()));
            } else {
                log.info(String.format("Message sent to Kafka topic %s successfully", topic));
            }
        });
    }
}
