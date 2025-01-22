package finalassignmentbackend.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import finalassignmentbackend.entity.BackupRestore;
import finalassignmentbackend.entity.RequestHistory;
import finalassignmentbackend.mapper.BackupRestoreMapper;
import finalassignmentbackend.mapper.RequestHistoryMapper;
import io.quarkus.cache.CacheInvalidate;
import io.quarkus.cache.CacheResult;
import io.smallrye.reactive.messaging.MutinyEmitter;
import io.smallrye.reactive.messaging.kafka.api.OutgoingKafkaRecordMetadata;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.enterprise.event.Event;
import jakarta.enterprise.event.Observes;
import jakarta.enterprise.event.TransactionPhase;
import jakarta.inject.Inject;
import jakarta.transaction.Transactional;
import lombok.Getter;
import org.eclipse.microprofile.reactive.messaging.Channel;
import org.eclipse.microprofile.reactive.messaging.Message;

import java.util.List;
import java.util.logging.Logger;

@ApplicationScoped
public class BackupRestoreService {

    private static final Logger log = Logger.getLogger(BackupRestoreService.class.getName());

    @Inject
    BackupRestoreMapper backupRestoreMapper;

    @Inject
    RequestHistoryMapper requestHistoryMapper;

    @Inject
    Event<BackupEvent> backupEvent;

    @Inject
    @Channel("backup-events-out")
    MutinyEmitter<BackupRestore> backupEmitter;

    @Getter
    public static class BackupEvent {
        private final BackupRestore backupRestore;
        private final String action; // "create" or "update"

        public BackupEvent(BackupRestore backupRestore, String action) {
            this.backupRestore = backupRestore;
            this.action = action;
        }
    }

    @Transactional
    @CacheInvalidate(cacheName = "backupCache")
    public void checkAndInsertIdempotency(String idempotencyKey, BackupRestore backupRestore, String action) {
        // 查询 request_history
        RequestHistory existingRequest = requestHistoryMapper.selectByIdempotencyKey(idempotencyKey);
        if (existingRequest != null) {
            // 已有此 key -> 重复请求
            log.warning(String.format("Duplicate request detected (idempotencyKey=%s)", idempotencyKey));
            throw new RuntimeException("Duplicate request detected");
        }

        // 不存在 -> 插入一条 PROCESSING
        RequestHistory newRequest = new RequestHistory();
        newRequest.setIdempotentKey(idempotencyKey);
        newRequest.setBusinessStatus("PROCESSING");

        try {
            requestHistoryMapper.insert(newRequest);
        } catch (Exception e) {
            // 若并发下同 key 导致唯一索引冲突
            log.severe("Failed to insert requestHistory for idempotencyKey=" + idempotencyKey + ", " + e.getMessage());
            throw new RuntimeException("Duplicate request or DB insert error", e);
        }

        backupEvent.fire(new BackupRestoreService.BackupEvent(backupRestore, action));

        Integer backupId = backupRestore.getBackupId();
        newRequest.setBusinessStatus("SUCCESS");
        newRequest.setBusinessId(backupId);
        requestHistoryMapper.updateById(newRequest);
    }

    @Transactional
    @CacheInvalidate(cacheName = "backupCache")
    public void createBackup(BackupRestore backup) {
        BackupRestore existingBackup = backupRestoreMapper.selectById(backup.getBackupId());
        if (existingBackup == null) {
            backupRestoreMapper.insert(backup);
        } else {
            backupRestoreMapper.updateById(backup);
        }
    }

    @Transactional
    @CacheInvalidate(cacheName = "backupCache")
    public void updateBackup(BackupRestore backup) {
        BackupRestore existingBackup = backupRestoreMapper.selectById(backup.getBackupId());
        if (existingBackup == null) {
            backupRestoreMapper.insert(backup);
        } else {
            backupRestoreMapper.updateById(backup);
        }
    }

    @Transactional
    @CacheInvalidate(cacheName = "backupCache")
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

    @CacheResult(cacheName = "backupCache")
    public BackupRestore getBackupById(Integer backupId) {
        if (backupId == null || backupId <= 0 || backupId >= Integer.MAX_VALUE) {
            throw new IllegalArgumentException("Invalid backup ID" + backupId);
        }
        return backupRestoreMapper.selectById(backupId);
    }

    @CacheResult(cacheName = "backupCache")
    public List<BackupRestore> getAllBackups() {
        return backupRestoreMapper.selectList(null);
    }

    @CacheResult(cacheName = "backupCache")
    public BackupRestore getBackupByFileName(String backupFileName) {
        if (backupFileName == null || backupFileName.trim().isEmpty()) {
            throw new IllegalArgumentException("Invalid backup file name");
        }
        QueryWrapper<BackupRestore> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("backup_file_name", backupFileName);
        return backupRestoreMapper.selectOne(queryWrapper);
    }

    @CacheResult(cacheName = "backupCache")
    public List<BackupRestore> getBackupsByTime(String backupTime) {
        if (backupTime == null || backupTime.trim().isEmpty()) {
            throw new IllegalArgumentException("Invalid backup time");
        }
        QueryWrapper<BackupRestore> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("backup_time", backupTime);
        return backupRestoreMapper.selectList(queryWrapper);
    }

    public void onBackupEvent(@Observes(during = TransactionPhase.AFTER_SUCCESS) BackupEvent event) {
        String topic = event.getAction().equals("create") ? "backup_processed_create" : "backup_processed_update";
        sendKafkaMessage(topic, event.getBackupRestore());
    }

    private void sendKafkaMessage(String topic, BackupRestore backup) {
        OutgoingKafkaRecordMetadata<String> metadata = OutgoingKafkaRecordMetadata.<String>builder()
                .withTopic(topic)
                .build();

        Message<BackupRestore> message = Message.of(backup).addMetadata(metadata);

        backupEmitter.sendMessage(message)
                .await().indefinitely();

        log.info(String.format("Message sent to Kafka topic %s successfully", topic));
    }
}
