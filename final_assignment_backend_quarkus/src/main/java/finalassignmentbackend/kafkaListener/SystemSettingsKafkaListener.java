package finalassignmentbackend.kafkaListener;

import com.fasterxml.jackson.databind.ObjectMapper;
import finalassignmentbackend.entity.SysSettings;
import finalassignmentbackend.service.SysSettingsService;
import io.smallrye.common.annotation.RunOnVirtualThread;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.transaction.Transactional;
import org.eclipse.microprofile.reactive.messaging.Incoming;

import java.util.logging.Level;
import java.util.logging.Logger;

// Kafka listener for system settings messages (new schema)
@ApplicationScoped
public class SystemSettingsKafkaListener {

    private static final Logger log = Logger.getLogger(SystemSettingsKafkaListener.class.getName());

    @Inject
    SysSettingsService sysSettingsService;

    @Inject
    ObjectMapper objectMapper;

    @Incoming("system_settings_create")
    @Transactional
    @RunOnVirtualThread
    public void onSettingsCreateReceived(String message) {
        log.log(Level.INFO, "Received Kafka create message: {0}", message);
        processMessage(message, "create", sysSettingsService::createSysSettings);
    }

    @Incoming("system_settings_update")
    @Transactional
    @RunOnVirtualThread
    public void onSettingsUpdateReceived(String message) {
        log.log(Level.INFO, "Received Kafka update message: {0}", message);
        processMessage(message, "update", sysSettingsService::updateSysSettings);
    }

    private void processMessage(String message, String action, MessageProcessor<SysSettings> processor) {
        try {
            SysSettings record = deserializeMessage(message);
            if ("create".equals(action)) {
                record.setSettingId(null);
            }
            processor.process(record);
            log.info(String.format("System settings %s processed: %s", action, record));
        } catch (Exception e) {
            log.log(Level.SEVERE, String.format("Failed to process system settings %s message: %s", action, message), e);
            throw new RuntimeException(String.format("Failed to process system settings %s message", action), e);
        }
    }

    private SysSettings deserializeMessage(String message) {
        try {
            return objectMapper.readValue(message, SysSettings.class);
        } catch (Exception e) {
            log.log(Level.SEVERE, "Failed to deserialize message: {0}", message);
            throw new RuntimeException("Failed to deserialize message", e);
        }
    }

    @FunctionalInterface
    private interface MessageProcessor<T> {
        void process(T t) throws Exception;
    }
}
