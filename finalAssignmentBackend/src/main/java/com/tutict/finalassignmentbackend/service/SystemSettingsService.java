package com.tutict.finalassignmentbackend.service;

import com.tutict.finalassignmentbackend.config.websocket.WsAction;
import com.tutict.finalassignmentbackend.entity.RequestHistory;
import com.tutict.finalassignmentbackend.mapper.RequestHistoryMapper;
import com.tutict.finalassignmentbackend.mapper.SystemSettingsMapper;
import com.tutict.finalassignmentbackend.entity.SystemSettings;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.logging.Logger;


// 系统设置服务类
@Service
public class SystemSettingsService {

    private static final Logger log = Logger.getLogger(SystemSettingsService.class.getName());

    private final SystemSettingsMapper systemSettingsMapper;
    private final RequestHistoryMapper requestHistoryMapper;
    private final KafkaTemplate<String, SystemSettings> kafkaTemplate;

    @Autowired
    public SystemSettingsService(SystemSettingsMapper systemSettingsMapper,
                                 RequestHistoryMapper requestHistoryMapper,
                                 KafkaTemplate<String, SystemSettings> kafkaTemplate) {
        this.systemSettingsMapper = systemSettingsMapper;
        this.requestHistoryMapper = requestHistoryMapper;
        this.kafkaTemplate = kafkaTemplate;
    }

    @Transactional
    @CacheEvict(cacheNames = "systemSettingsCache", allEntries = true)
    @WsAction(service = "SystemSettingsService", action = "checkAndInsertIdempotency")
    public void checkAndInsertIdempotency(String idempotencyKey, SystemSettings systemSettings) {
        // Query request_history
        RequestHistory existingRequest = requestHistoryMapper.selectByIdempotencyKey(idempotencyKey);
        if (existingRequest != null) {
            log.warning(String.format("Duplicate request detected (idempotencyKey=%s)", idempotencyKey));
            throw new RuntimeException("Duplicate request detected");
        }

        // Insert a new "PROCESSING" entry if not found
        RequestHistory newRequest = new RequestHistory();
        newRequest.setIdempotentKey(idempotencyKey);
        newRequest.setBusinessStatus("PROCESSING");

        try {
            requestHistoryMapper.insert(newRequest);
        } catch (Exception e) {
            log.severe("Failed to insert requestHistory for idempotencyKey=" + idempotencyKey + ", " + e.getMessage());
            throw new RuntimeException("Duplicate request or DB insert error", e);
        }

        // Send event to Kafka
        sendKafkaMessage(systemSettings);

        // Update request status to SUCCESS
        String systemSettingsName = systemSettings.getSystemName();
        newRequest.setBusinessStatus("SUCCESS " + systemSettingsName);
        requestHistoryMapper.updateById(newRequest);
    }

    @Cacheable(cacheNames = "systemSettingsCache")
    @WsAction(service = "SystemSettingsService", action = "getSystemSettings")
    public SystemSettings getSystemSettings() {
        return systemSettingsMapper.selectById(1);
    }

    @Transactional
    @CacheEvict(cacheNames = "systemSettingsCache", allEntries = true)
    public void updateSystemSettings(SystemSettings systemSettings) {
        try {
            systemSettingsMapper.updateById(systemSettings);
        } catch (Exception e) {
            log.warning("Exception occurred while updating system settings or firing event");
            throw new RuntimeException("Failed to update system settings", e);
        }
    }

    @Cacheable(cacheNames = "systemSettingsCache")
    @WsAction(service = "SystemSettingsService", action = "getSystemName")
    public String getSystemName() {
        SystemSettings systemSettings = getSystemSettings();
        return systemSettings != null ? systemSettings.getSystemName() : null;
    }

    @Cacheable(cacheNames = "systemSettingsCache")
    @WsAction(service = "SystemSettingsService", action = "getSystemVersion")
    public String getSystemVersion() {
        SystemSettings systemSettings = getSystemSettings();
        return systemSettings != null ? systemSettings.getSystemVersion() : null;
    }

    @Cacheable(cacheNames = "systemSettingsCache")
    @WsAction(service = "SystemSettingsService", action = "getSystemDescription")
    public String getSystemDescription() {
        SystemSettings systemSettings = getSystemSettings();
        return systemSettings != null ? systemSettings.getSystemDescription() : null;
    }

    @Cacheable(cacheNames = "systemSettingsCache")
    @WsAction(service = "SystemSettingsService", action = "getCopyrightInfo")
    public String getCopyrightInfo() {
        SystemSettings systemSettings = getSystemSettings();
        return systemSettings != null ? systemSettings.getCopyrightInfo() : null;
    }

    @Cacheable(cacheNames = "systemSettingsCache")
    @WsAction(service = "SystemSettingsService", action = "getStoragePath")
    public String getStoragePath() {
        SystemSettings systemSettings = getSystemSettings();
        return systemSettings != null ? systemSettings.getStoragePath() : null;
    }

    @Cacheable(cacheNames = "systemSettingsCache")
    @WsAction(service = "SystemSettingsService", action = "getLoginTimeout")
    public int getLoginTimeout() {
        SystemSettings systemSettings = getSystemSettings();
        return systemSettings != null ? systemSettings.getLoginTimeout() : 0;
    }

    @Cacheable(cacheNames = "systemSettingsCache")
    @WsAction(service = "SystemSettingsService", action = "getSessionTimeout")
    public int getSessionTimeout() {
        SystemSettings systemSettings = getSystemSettings();
        return systemSettings != null ? systemSettings.getSessionTimeout() : 0;
    }

    @Cacheable(cacheNames = "systemSettingsCache")
    @WsAction(service = "SystemSettingsService", action = "getDateFormat")
    public String getDateFormat() {
        SystemSettings systemSettings = getSystemSettings();
        return systemSettings != null ? systemSettings.getDateFormat() : null;
    }

    @Cacheable(cacheNames = "systemSettingsCache")
    @WsAction(service = "SystemSettingsService", action = "getPageSize")
    public int getPageSize() {
        SystemSettings systemSettings = getSystemSettings();
        return systemSettings != null ? systemSettings.getPageSize() : 0;
    }

    @Cacheable(cacheNames = "systemSettingsCache")
    @WsAction(service = "SystemSettingsService", action = "getSmtpServer")
    public String getSmtpServer() {
        SystemSettings systemSettings = getSystemSettings();
        return systemSettings != null ? systemSettings.getSmtpServer() : null;
    }

    @Cacheable(cacheNames = "systemSettingsCache")
    @WsAction(service = "SystemSettingsService", action = "getEmailAccount")
    public String getEmailAccount() {
        SystemSettings systemSettings = getSystemSettings();
        return systemSettings != null ? systemSettings.getEmailAccount() : null;
    }

    @Cacheable(cacheNames = "systemSettingsCache")
    @WsAction(service = "SystemSettingsService", action = "getEmailPassword")
    public String getEmailPassword() {
        SystemSettings systemSettings = getSystemSettings();
        return systemSettings != null ? systemSettings.getEmailPassword() : null;
    }

    // Listen for the system settings update event
    public void onSystemSettingsUpdated(SystemSettings systemSettings) {
        sendKafkaMessage(systemSettings);
    }

    private void sendKafkaMessage(SystemSettings systemSettings) {
        kafkaTemplate.send("system_settings_update", systemSettings);
        log.info("Message sent to Kafka topic system_settings_update successfully");
    }
}