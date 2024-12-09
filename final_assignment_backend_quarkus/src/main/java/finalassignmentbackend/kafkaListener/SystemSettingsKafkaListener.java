package finalassignmentbackend.kafkaListener;

import com.fasterxml.jackson.databind.ObjectMapper;
import finalassignmentbackend.entity.SystemSettings;
import finalassignmentbackend.service.SystemSettingsService;
import io.smallrye.common.annotation.RunOnVirtualThread;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.transaction.Transactional;
import org.eclipse.microprofile.reactive.messaging.Incoming;

import java.util.logging.Level;
import java.util.logging.Logger;

@ApplicationScoped
public class SystemSettingsKafkaListener {

    private static final Logger log = Logger.getLogger(SystemSettingsKafkaListener.class.getName());

    @Inject
    SystemSettingsService systemSettingsService;

    @Inject
    ObjectMapper objectMapper;

    @Incoming("system_settings_update")
    @Transactional
    @RunOnVirtualThread
    public void onSystemSettingsUpdateReceived(String message) {
        processMessage(message, systemSettingsService::updateSystemSettings);
    }

    private void processMessage(String message, MessageProcessor<SystemSettings> processor) {
        try {
            SystemSettings systemSettings = deserializeMessage(message);
            processor.process(systemSettings);
            log.info(String.format("System settings %s action processed successfully: %s", "update", message));
        } catch (Exception e) {
            log.log(Level.SEVERE, String.format("Error processing %s system settings message: %s", "update", message), e);
            throw new RuntimeException(String.format("Failed to process %s system settings message", "update"), e);
        }
    }

    private SystemSettings deserializeMessage(String message) {
        try {
            return objectMapper.readValue(message, SystemSettings.class);
        } catch (Exception e) {
            log.log(Level.SEVERE, "Failed to deserialize message: " + message, e);
            throw new RuntimeException("Failed to deserialize message", e);
        }
    }

    @FunctionalInterface
    private interface MessageProcessor<T> {
        void process(T t) throws Exception;
    }
}
