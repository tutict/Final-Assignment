package finalassignmentbackend.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import finalassignmentbackend.mapper.BackupRestoreMapper;
import finalassignmentbackend.entity.BackupRestore;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.transaction.Transactional;
import org.eclipse.microprofile.reactive.messaging.Channel;
import org.eclipse.microprofile.reactive.messaging.Emitter;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.List;

@ApplicationScoped
public class BackupRestoreService {

    private static final Logger log = LoggerFactory.getLogger(BackupRestoreService.class);

    @Inject
    BackupRestoreMapper backupRestoreMapper;

    @Inject
    @Channel("backup_create")
    Emitter<BackupRestore> backupRestoreCreateEmitter;

    @Inject
    @Channel("backup_update")
    Emitter<BackupRestore> backupRestoreUpdateEmitter;

    @Transactional
    public void createBackup(BackupRestore backup) {
        try {
            // 异步发送消息到 Kafka，并处理发送结果
            backupRestoreCreateEmitter.send(backup).toCompletableFuture().exceptionally(ex -> {

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
            backupRestoreUpdateEmitter.send(backup).toCompletableFuture().exceptionally(ex -> {

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
