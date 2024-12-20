package com.tutict.finalassignmentbackend.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.tutict.finalassignmentbackend.mapper.BackupRestoreMapper;
import com.tutict.finalassignmentbackend.entity.BackupRestore;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.CachePut;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.kafka.support.SendResult;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

// 备份恢复服务类，处理备份创建、更新、查询和删除操作
@Service
public class BackupRestoreService {

    // 日志记录器，用于记录应用运行时的日志信息
    private static final Logger log = LoggerFactory.getLogger(BackupRestoreService.class);

    // 备份恢复数据访问对象，用于数据库操作
    private final BackupRestoreMapper backupRestoreMapper;
    // Kafka消息模板，用于发送消息到Kafka主题
    private final KafkaTemplate<String, BackupRestore> kafkaTemplate;

    // 构造函数，通过依赖注入初始化BackupRestoreMapper和KafkaTemplate
    @Autowired
    public BackupRestoreService(BackupRestoreMapper backupRestoreMapper, KafkaTemplate<String, BackupRestore> kafkaTemplate) {
        this.backupRestoreMapper = backupRestoreMapper;
        this.kafkaTemplate = kafkaTemplate;
    }

    /**
     * 创建备份
     * @param backup 要创建的备份对象，包含备份的所有相关信息
     */
    @Transactional
    @CacheEvict(value = "backupCache", key = "#backup.backupId")
    public void createBackup(BackupRestore backup) {
        try {
            // 同步发送 Kafka 消息
            sendKafkaMessage("backup_create", backup);
            // 数据库插入
            backupRestoreMapper.insert(backup);
        } catch (Exception e) {
            log.error("Exception occurred while creating backup or sending Kafka message", e);
            throw new RuntimeException("Failed to create backup", e);
        }
    }

    /**
     * 获取所有备份列表
     * @return 包含所有备份的列表
     */
    @Cacheable(value = "backupCache", key = "'allBackups'")
    public List<BackupRestore> getAllBackups() {
        return backupRestoreMapper.selectList(null);
    }

    /**
     * 根据ID获取备份
     * @param backupId 备份的唯一标识符
     * @return 指定ID的备份对象，如果不存在则返回"Invalid backup ID"
     */
    @Cacheable(value = "backupCache", key = "#backupId")
    public BackupRestore getBackupById(Integer backupId) {
        if (backupId <= 0) {
            throw new IllegalArgumentException("Invalid backup ID");
        }
        return backupRestoreMapper.selectById(backupId);
    }

    /**
     * 删除指定ID的备份
     * @param backupId 要删除的备份的ID
     */
    @Transactional
    @CacheEvict(value = "backupCache", key = "#backupId")
    public void deleteBackup(Integer backupId) {
        try {
            int result = backupRestoreMapper.deleteById(backupId);
            if (result > 0) {
                log.info("Backup with ID {} deleted successfully", backupId);
            } else {
                log.error("Failed to delete backup with ID {}", backupId);
            }
        } catch (Exception e) {
            log.error("Exception occurred while deleting backup", e);
            throw new RuntimeException("Failed to delete backup", e);
        }
    }

    /**
     * 更新备份信息
     * @param backup 包含更新后的备份信息的对象
     */
    @Transactional
    @CachePut(value = "backupCache", key = "#backup.backupId")
    public void updateBackup(BackupRestore backup) {
        try {
            // 同步发送 Kafka 消息
            sendKafkaMessage("backup_update", backup);
            // 更新数据库记录
            backupRestoreMapper.updateById(backup);
        } catch (Exception e) {
            log.error("Exception occurred while updating backup or sending Kafka message", e);
            throw new RuntimeException("Failed to update backup", e);
        }
    }

    /**
     * 根据文件名获取备份
     * @param backupFileName 备份文件名
     * @return 指定文件名的备份对象，如果不存在则返回"Invalid backup file name"
     * @throws IllegalArgumentException 如果文件名为空或为null
     */
    @Cacheable(value = "backupCache", key = "#root.methodName + '_' + #backupFileName")
    public BackupRestore getBackupByFileName(String backupFileName) {
        if (backupFileName == null || backupFileName.trim().isEmpty()) {
            throw new IllegalArgumentException("Invalid backup file name");
        }
        QueryWrapper<BackupRestore> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("backupFileName", backupFileName);
        return backupRestoreMapper.selectOne(queryWrapper);
    }

    /**
     * 根据时间获取备份列表
     * @param backupTime 备份时间
     * @return 指定时间的备份列表，如果不存在则返回"Invalid backup time"
     * @throws IllegalArgumentException 如果时间参数为空或为null
     */
    @Cacheable(value = "backupCache", key = "#root.methodName + '_' + #backupTime")
    public List<BackupRestore> getBackupsByTime(String backupTime) {
        if (backupTime == null || backupTime.trim().isEmpty()) {
            throw new IllegalArgumentException("Invalid backup time");
        }
        QueryWrapper<BackupRestore> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("backupTime", backupTime);
        return backupRestoreMapper.selectList(queryWrapper);
    }

    // 发送 Kafka 消息的私有方法
    private void sendKafkaMessage(String topic, BackupRestore backup) throws Exception {
        SendResult<String, BackupRestore> sendResult = kafkaTemplate.send(topic, backup).get();
        log.info("Message sent to Kafka topic {} successfully: {}", topic, sendResult.toString());
    }
}