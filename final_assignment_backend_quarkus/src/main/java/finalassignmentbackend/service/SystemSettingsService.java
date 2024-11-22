package finalassignmentbackend.service;

import finalassignmentbackend.mapper.SystemSettingsMapper;
import finalassignmentbackend.entity.SystemSettings;
import io.quarkus.cache.CacheInvalidate;
import io.quarkus.cache.CacheResult;
import io.smallrye.reactive.messaging.kafka.KafkaRecord;
import io.smallrye.reactive.messaging.kafka.api.OutgoingKafkaRecordMetadata;
import org.jboss.logging.Logger;
import org.eclipse.microprofile.reactive.messaging.Channel;
import org.eclipse.microprofile.reactive.messaging.Emitter;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.transaction.Transactional;

@ApplicationScoped
public class SystemSettingsService {

    private static final Logger log = Logger.getLogger(SystemSettingsService.class);

    @Inject
    SystemSettingsMapper systemSettingsMapper;

    @Inject
    @Channel("system-settings-out")
    Emitter<SystemSettings> systemSettingsEmitter;

    @CacheResult(cacheName = "systemSettingsCache")
    public SystemSettings getSystemSettings() {
        return systemSettingsMapper.selectById(1);
    }

    @Transactional
    @CacheInvalidate(cacheName = "systemSettingsCache")
    public SystemSettings updateSystemSettings(SystemSettings systemSettings) {
        try {
            sendKafkaMessage(systemSettings);
            systemSettingsMapper.updateById(systemSettings);
            return systemSettings;
        } catch (Exception e) {
            log.error("Exception occurred while updating system settings or sending Kafka message", e);
            throw new RuntimeException("Failed to update system settings", e);
        }
    }

    @CacheResult(cacheName = "systemSettingsCache")
    public String getSystemName() {
        SystemSettings systemSettings = getSystemSettings();
        return systemSettings != null ? systemSettings.getSystemName() : null;
    }

    @CacheResult(cacheName = "systemSettingsCache")
    public String getSystemVersion() {
        SystemSettings systemSettings = getSystemSettings();
        return systemSettings != null ? systemSettings.getSystemVersion() : null;
    }

    @CacheResult(cacheName = "systemSettingsCache")
    public String getSystemDescription() {
        SystemSettings systemSettings = getSystemSettings();
        return systemSettings != null ? systemSettings.getSystemDescription() : null;
    }

    @CacheResult(cacheName = "systemSettingsCache")
    public String getCopyrightInfo() {
        SystemSettings systemSettings = getSystemSettings();
        return systemSettings != null ? systemSettings.getCopyrightInfo() : null;
    }

    @CacheResult(cacheName = "systemSettingsCache")
    public String getStoragePath() {
        SystemSettings systemSettings = getSystemSettings();
        return systemSettings != null ? systemSettings.getStoragePath() : null;
    }

    @CacheResult(cacheName = "systemSettingsCache")
    public int getLoginTimeout() {
        SystemSettings systemSettings = getSystemSettings();
        return systemSettings != null ? systemSettings.getLoginTimeout() : 0;
    }

    @CacheResult(cacheName = "systemSettingsCache")
    public int getSessionTimeout() {
        SystemSettings systemSettings = getSystemSettings();
        return systemSettings != null ? systemSettings.getSessionTimeout() : 0;
    }

    @CacheResult(cacheName = "systemSettingsCache")
    public String getDateFormat() {
        SystemSettings systemSettings = getSystemSettings();
        return systemSettings != null ? systemSettings.getDateFormat() : null;
    }

    @CacheResult(cacheName = "systemSettingsCache")
    public int getPageSize() {
        SystemSettings systemSettings = getSystemSettings();
        return systemSettings != null ? systemSettings.getPageSize() : 0;
    }

    @CacheResult(cacheName = "systemSettingsCache")
    public String getSmtpServer() {
        SystemSettings systemSettings = getSystemSettings();
        return systemSettings != null ? systemSettings.getSmtpServer() : null;
    }

    @CacheResult(cacheName = "systemSettingsCache")
    public String getEmailAccount() {
        SystemSettings systemSettings = getSystemSettings();
        return systemSettings != null ? systemSettings.getEmailAccount() : null;
    }

    @CacheResult(cacheName = "systemSettingsCache")
    public String getEmailPassword() {
        SystemSettings systemSettings = getSystemSettings();
        return systemSettings != null ? systemSettings.getEmailPassword() : null;
    }

    private void sendKafkaMessage(SystemSettings systemSettings) {
        try {
            var metadata = OutgoingKafkaRecordMetadata.<String>builder().withTopic("system_settings_update").build();
            KafkaRecord<String, SystemSettings> record = (KafkaRecord<String, SystemSettings>) KafkaRecord.of(systemSettings.getSystemName(), systemSettings).addMetadata(metadata);
            systemSettingsEmitter.send(record);
            log.info("Message sent to Kafka topic {} successfully");
        } catch (Exception e) {
            log.error("Exception occurred while sending Kafka message", e);
            throw new RuntimeException("Failed to send Kafka message", e);
        }
    }
}
