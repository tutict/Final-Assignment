package finalassignmentbackend.service;

import finalassignmentbackend.config.websocket.WsAction;
import finalassignmentbackend.entity.RequestHistory;
import finalassignmentbackend.entity.SystemSettings;
import finalassignmentbackend.mapper.RequestHistoryMapper;
import finalassignmentbackend.mapper.SystemSettingsMapper;
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

import java.util.logging.Logger;

@ApplicationScoped
public class SystemSettingsService {

    private static final Logger log = Logger.getLogger(SystemSettingsService.class.getName());

    @Inject
    SystemSettingsMapper systemSettingsMapper;

    @Inject
    RequestHistoryMapper requestHistoryMapper;

    @Inject
    Event<SystemSettingsEvent> systemSettingsEvent;

    @Inject
    @Channel("system-settings-out")
    MutinyEmitter<SystemSettings> systemSettingsEmitter;

    @Getter
    public static class SystemSettingsEvent {
        private final SystemSettings systemSettings;

        public SystemSettingsEvent(SystemSettings systemSettings) {
            this.systemSettings = systemSettings;
        }
    }

    @Transactional
    @CacheInvalidate(cacheName = "systemSettingsCache")
    @WsAction(service = "systemSettings", action = "checkCreateAndUpdate")
    public void checkAndInsertIdempotency(String idempotencyKey, SystemSettings systemSettings) {
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

        systemSettingsEvent.fire(new SystemSettingsService.SystemSettingsEvent(systemSettings));

        String systemSettingsName = systemSettings.getSystemName();
        newRequest.setBusinessStatus("SUCCESS" + systemSettingsName);
        requestHistoryMapper.updateById(newRequest);
    }

    @CacheResult(cacheName = "systemSettingsCache")
    @WsAction(service = "systemSettings", action = "getSystemSettings")
    public SystemSettings getSystemSettings() {
        return systemSettingsMapper.selectById(1);
    }

    @Transactional
    @CacheInvalidate(cacheName = "systemSettingsCache")
    public void updateSystemSettings(SystemSettings systemSettings) {
        try {
            systemSettingsMapper.updateById(systemSettings);
        } catch (Exception e) {
            log.warning("Exception occurred while updating system settings or firing event");
            throw new RuntimeException("Failed to update system settings", e);
        }
    }

    @CacheResult(cacheName = "systemSettingsCache")
    @WsAction(service = "systemSettings", action = "getSystemName")
    public String getSystemName() {
        SystemSettings systemSettings = getSystemSettings();
        return systemSettings != null ? systemSettings.getSystemName() : null;
    }

    @CacheResult(cacheName = "systemSettingsCache")
    @WsAction(service = "systemSettings", action = "getSystemVersion")
    public String getSystemVersion() {
        SystemSettings systemSettings = getSystemSettings();
        return systemSettings != null ? systemSettings.getSystemVersion() : null;
    }

    @CacheResult(cacheName = "systemSettingsCache")
    @WsAction(service = "systemSettings", action = "getSystemDescription")
    public String getSystemDescription() {
        SystemSettings systemSettings = getSystemSettings();
        return systemSettings != null ? systemSettings.getSystemDescription() : null;
    }

    @CacheResult(cacheName = "systemSettingsCache")
    @WsAction(service = "systemSettings", action = "getCopyrightInfo")
    public String getCopyrightInfo() {
        SystemSettings systemSettings = getSystemSettings();
        return systemSettings != null ? systemSettings.getCopyrightInfo() : null;
    }

    @CacheResult(cacheName = "systemSettingsCache")
    @WsAction(service = "systemSettings", action = "getStoragePath")
    public String getStoragePath() {
        SystemSettings systemSettings = getSystemSettings();
        return systemSettings != null ? systemSettings.getStoragePath() : null;
    }

    @CacheResult(cacheName = "systemSettingsCache")
    @WsAction(service = "systemSettings", action = "getLoginTimeout")
    public int getLoginTimeout() {
        SystemSettings systemSettings = getSystemSettings();
        return systemSettings != null ? systemSettings.getLoginTimeout() : 0;
    }

    @CacheResult(cacheName = "systemSettingsCache")
    @WsAction(service = "systemSettings", action = "getSessionTimeout")
    public int getSessionTimeout() {
        SystemSettings systemSettings = getSystemSettings();
        return systemSettings != null ? systemSettings.getSessionTimeout() : 0;
    }

    @CacheResult(cacheName = "systemSettingsCache")
    @WsAction(service = "systemSettings", action = "getDateFormat")
    public String getDateFormat() {
        SystemSettings systemSettings = getSystemSettings();
        return systemSettings != null ? systemSettings.getDateFormat() : null;
    }

    @CacheResult(cacheName = "systemSettingsCache")
    @WsAction(service = "systemSettings", action = "getPageSize")
    public int getPageSize() {
        SystemSettings systemSettings = getSystemSettings();
        return systemSettings != null ? systemSettings.getPageSize() : 0;
    }

    @CacheResult(cacheName = "systemSettingsCache")
    @WsAction(service = "systemSettings", action = "getSmtpServer")
    public String getSmtpServer() {
        SystemSettings systemSettings = getSystemSettings();
        return systemSettings != null ? systemSettings.getSmtpServer() : null;
    }

    @CacheResult(cacheName = "systemSettingsCache")
    @WsAction(service = "systemSettings", action = "getEmailAccount")
    public String getEmailAccount() {
        SystemSettings systemSettings = getSystemSettings();
        return systemSettings != null ? systemSettings.getEmailAccount() : null;
    }

    @CacheResult(cacheName = "systemSettingsCache")
    @WsAction(service = "systemSettings", action = "getEmailPassword")
    public String getEmailPassword() {
        SystemSettings systemSettings = getSystemSettings();
        return systemSettings != null ? systemSettings.getEmailPassword() : null;
    }

    // 监听事务提交事件
    public void onSystemSettingsUpdated(@Observes(during = TransactionPhase.AFTER_SUCCESS) SystemSettingsEvent event) {
        sendKafkaMessage(event.getSystemSettings());
    }

    private void sendKafkaMessage(SystemSettings systemSettings) {
        var metadata = OutgoingKafkaRecordMetadata.<String>builder()
                .withTopic("system_settings_update")
                .build();

        // 使用 Message 构建消息
        Message<SystemSettings> message = Message.of(systemSettings).addMetadata(metadata);

        // 使用 MutinyEmitter 发送消息
        systemSettingsEmitter.sendMessage(message)
                .await().indefinitely();

        log.info("Message sent to Kafka topic system_settings_update successfully");
    }
}
