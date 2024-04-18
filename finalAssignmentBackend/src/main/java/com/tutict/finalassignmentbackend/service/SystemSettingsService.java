package com.tutict.finalassignmentbackend.service;

import com.tutict.finalassignmentbackend.mapper.SystemSettingsMapper;
import com.tutict.finalassignmentbackend.entity.SystemSettings;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Service;

@Service
public class SystemSettingsService {

    private final SystemSettingsMapper systemSettingsMapper;
    private final KafkaTemplate<String, SystemSettings> kafkaTemplate;

    @Autowired
    public SystemSettingsService(SystemSettingsMapper systemSettingsMapper, KafkaTemplate<String, SystemSettings> kafkaTemplate) {
        this.systemSettingsMapper = systemSettingsMapper;
        this.kafkaTemplate = kafkaTemplate;
    }

    // 获取系统设置
    public SystemSettings getSystemSettings() {
        return systemSettingsMapper.selectById(1);
    }

    // 更新系统设置
    public void updateSystemSettings(SystemSettings systemSettings) {
        systemSettingsMapper.updateById(systemSettings);
        // 发送更新后的系统设置到 Kafka 主题
        kafkaTemplate.send("system_settings_topic", systemSettings);
    }

    // 获取系统名称
    public String getSystemName() {
        SystemSettings systemSettings = systemSettingsMapper.selectById(1);
        return systemSettings != null ? systemSettings.getSystemName() : null;
    }

    // 获取系统版本
    public String getSystemVersion() {
        SystemSettings systemSettings = systemSettingsMapper.selectById(1);
        return systemSettings != null ? systemSettings.getSystemVersion() : null;
    }

    // 获取系统描述
    public String getSystemDescription() {
        SystemSettings systemSettings = systemSettingsMapper.selectById(1);
        return systemSettings != null ? systemSettings.getSystemDescription() : null;
    }

    // 获取版权信息
    public String getCopyrightInfo() {
        SystemSettings systemSettings = systemSettingsMapper.selectById(1);
        return systemSettings != null ? systemSettings.getCopyrightInfo() : null;
    }

    // 获取存储路径
    public String getStoragePath() {
        SystemSettings systemSettings = systemSettingsMapper.selectById(1);
        return systemSettings != null ? systemSettings.getStoragePath() : null;
    }

    // 获取登录超时时间
    public int getLoginTimeout() {
        SystemSettings systemSettings = systemSettingsMapper.selectById(1);
        return systemSettings != null ? systemSettings.getLoginTimeout() : 0;
    }

    // 获取会话超时时间
    public int getSessionTimeout() {
        SystemSettings systemSettings = systemSettingsMapper.selectById(1);
        return systemSettings != null ? systemSettings.getSessionTimeout() : 0;
    }

    // 获取日期格式
    public String getDateFormat() {
        SystemSettings systemSettings = systemSettingsMapper.selectById(1);
        return systemSettings != null ? systemSettings.getDateFormat() : null;
    }

    // 获取分页大小
    public int getPageSize() {
        SystemSettings systemSettings = systemSettingsMapper.selectById(1);
        return systemSettings != null ? systemSettings.getPageSize() : 0;
    }

    // 获取SMTP服务器
    public String getSmtpServer() {
        SystemSettings systemSettings = systemSettingsMapper.selectById(1);
        return systemSettings != null ? systemSettings.getSmtpServer() : null;
    }

    // 获取邮箱账号
    public String getEmailAccount() {
        SystemSettings systemSettings = systemSettingsMapper.selectById(1);
        return systemSettings != null ? systemSettings.getEmailAccount() : null;
    }

    // 获取邮箱密码
    public String getEmailPassword() {
        SystemSettings systemSettings = systemSettingsMapper.selectById(1);
        return systemSettings != null ? systemSettings.getEmailPassword() : null;
    }

}
