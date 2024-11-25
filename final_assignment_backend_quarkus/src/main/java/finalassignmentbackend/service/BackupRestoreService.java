package finalassignmentbackend.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.oracle.svm.core.annotate.Inject;
import finalassignmentbackend.entity.BackupRestore;
import finalassignmentbackend.mapper.BackupRestoreMapper;
import io.quarkus.cache.CacheInvalidate;
import io.quarkus.cache.CacheResult;
import io.smallrye.reactive.messaging.kafka.KafkaRecord;
import io.smallrye.reactive.messaging.kafka.api.OutgoingKafkaRecordMetadata;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.transaction.Transactional;
import org.eclipse.microprofile.reactive.messaging.Channel;
import org.eclipse.microprofile.reactive.messaging.Emitter;

import java.util.List;
import java.util.logging.Logger;

@ApplicationScoped
public class BackupRestoreService {

    private static final Logger log = Logger.getLogger(String.valueOf(BackupRestoreService.class));

    @Inject
    BackupRestoreMapper backupRestoreMapper;

    @Inject
    @Channel("backup-events-out")
    Emitter<BackupRestore> backupEmitter;

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
        if (backupId <= 0) {
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
                log.info("Backup with ID {} deleted successfully");
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
        var metadata = OutgoingKafkaRecordMetadata.<String>builder().withTopic(topic).build();
        KafkaRecord<String, BackupRestore> record = (KafkaRecord<String, BackupRestore>) KafkaRecord.of(backup.getBackupId().toString(), backup).addMetadata(metadata);
        backupEmitter.send(record);
        log.info(String.format("Message sent to Kafka topic %s successfully", topic));
    }
}
