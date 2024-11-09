package com.tutict.finalassignmentbackend.service;

import com.tutict.finalassignmentbackend.mapper.SystemSettingsMapper;
import com.tutict.finalassignmentbackend.entity.SystemSettings;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.cache.annotation.CachePut;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.kafka.support.SendResult;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;


// 系统设置服务类
@Service
public class SystemSettingsService {

    // 日志记录器
    private static final Logger log = LoggerFactory.getLogger(SystemSettingsService.class);

    // 系统设置数据访问对象
    private final SystemSettingsMapper systemSettingsMapper;
    // Kafka消息模板
    private final KafkaTemplate<String, SystemSettings> kafkaTemplate;

    // 构造函数，初始化系统设置数据访问对象和Kafka模板
    @Autowired
    public SystemSettingsService(SystemSettingsMapper systemSettingsMapper, KafkaTemplate<String, SystemSettings> kafkaTemplate) {
        this.systemSettingsMapper = systemSettingsMapper;
        this.kafkaTemplate = kafkaTemplate;
    }

    // 获取系统设置
    // 通过数据访问对象根据id选择系统设置
    @Cacheable(cacheNames = "systemSettingsCache", key = "'systemSettings'")
    public SystemSettings getSystemSettings() {
        return systemSettingsMapper.selectById(1);
    }

    // 更新系统设置
    // 使用Spring业务管理器管理更新操作
    @Transactional
    @CachePut(cacheNames = "systemSettingsCache", key = "'systemSettings'")
    public SystemSettings updateSystemSettings(SystemSettings systemSettings) {
        try {
            // 同步发送系统设置更新消息到Kafka主题
            sendKafkaMessage(systemSettings);

            // 更新系统设置，业务管理器处理业务
            systemSettingsMapper.updateById(systemSettings);
            return systemSettings;
        } catch (Exception e) {
            // 记录更新系统设置或发送Kafka消息时的异常
            log.error("Exception occurred while updating system settings or sending Kafka message", e);
            // 异常由Spring业务管理器处理，可能触发业务回滚
            throw new RuntimeException("Failed to update system settings", e);
        }
    }

    // 获取系统名称
    @Cacheable(cacheNames = "systemSettingsCache", key = "'systemName'")
    public String getSystemName() {
        SystemSettings systemSettings = getSystemSettings();
        return systemSettings != null ? systemSettings.getSystemName() : null;
    }

    // 获取系统版本
    @Cacheable(cacheNames = "systemSettingsCache", key = "'systemVersion'")
    public String getSystemVersion() {
        SystemSettings systemSettings = getSystemSettings();
        return systemSettings != null ? systemSettings.getSystemVersion() : null;
    }

    // 获取系统描述
    @Cacheable(cacheNames = "systemSettingsCache", key = "'systemDescription'")
    public String getSystemDescription() {
        SystemSettings systemSettings = getSystemSettings();
        return systemSettings != null ? systemSettings.getSystemDescription() : null;
    }

    // 获取版权信息
    @Cacheable(cacheNames = "systemSettingsCache", key = "'copyrightInfo'")
    public String getCopyrightInfo() {
        SystemSettings systemSettings = getSystemSettings();
        return systemSettings != null ? systemSettings.getCopyrightInfo() : null;
    }

    // 获取存储路径
    @Cacheable(cacheNames = "systemSettingsCache", key = "'storagePath'")
    public String getStoragePath() {
        SystemSettings systemSettings = getSystemSettings();
        return systemSettings != null ? systemSettings.getStoragePath() : null;
    }

    // 获取登录超时时间
    @Cacheable(cacheNames = "systemSettingsCache", key = "'loginTimeout'")
    public int getLoginTimeout() {
        SystemSettings systemSettings = getSystemSettings();
        return systemSettings != null ? systemSettings.getLoginTimeout() : 0;
    }

    // 获取会话超时时间
    @Cacheable(cacheNames = "systemSettingsCache", key = "'sessionTimeout'")
    public int getSessionTimeout() {
        SystemSettings systemSettings = getSystemSettings();
        return systemSettings != null ? systemSettings.getSessionTimeout() : 0;
    }

    // 获取日期格式
    @Cacheable(cacheNames = "systemSettingsCache", key = "'dateFormat'")
    public String getDateFormat() {
        SystemSettings systemSettings = getSystemSettings();
        return systemSettings != null ? systemSettings.getDateFormat() : null;
    }

    // 获取分页大小
    @Cacheable(cacheNames = "systemSettingsCache", key = "'pageSize'")
    public int getPageSize() {
        SystemSettings systemSettings = getSystemSettings();
        return systemSettings != null ? systemSettings.getPageSize() : 0;
    }

    // 获取SMTP服务器
    @Cacheable(cacheNames = "systemSettingsCache", key = "'smtpServer'")
    public String getSmtpServer() {
        SystemSettings systemSettings = getSystemSettings();
        return systemSettings != null ? systemSettings.getSmtpServer() : null;
    }

    // 获取邮箱账号
    @Cacheable(cacheNames = "systemSettingsCache", key = "'emailAccount'")
    public String getEmailAccount() {
        SystemSettings systemSettings = getSystemSettings();
        return systemSettings != null ? systemSettings.getEmailAccount() : null;
    }

    // 获取邮箱密码
    @Cacheable(cacheNames = "systemSettingsCache", key = "'emailPassword'")
    public String getEmailPassword() {
        SystemSettings systemSettings = getSystemSettings();
        return systemSettings != null ? systemSettings.getEmailPassword() : null;
    }

    // 发送 Kafka 消息的私有方法
    private void sendKafkaMessage(SystemSettings systemSettings) throws Exception {
        SendResult<String, SystemSettings> sendResult = kafkaTemplate.send("system_settings_update", systemSettings).get();
        log.info("Message sent to Kafka topic {} successfully: {}", "system_settings_update", sendResult.toString());
    }
}
