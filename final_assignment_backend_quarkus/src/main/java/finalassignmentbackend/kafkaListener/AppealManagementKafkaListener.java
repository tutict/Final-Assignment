package finalassignmentbackend.kafkaListener;

import com.fasterxml.jackson.databind.ObjectMapper;
import finalassignmentbackend.entity.AppealManagement;
import finalassignmentbackend.service.AppealManagementService;
import io.smallrye.common.annotation.RunOnVirtualThread;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.transaction.Transactional;
import org.eclipse.microprofile.reactive.messaging.Incoming;

import java.util.logging.Level;
import java.util.logging.Logger;

@ApplicationScoped
public class AppealManagementKafkaListener {

    private static final Logger log = Logger.getLogger(AppealManagementKafkaListener.class.getName());

    @Inject
    AppealManagementService appealManagementService;

    @Inject
    ObjectMapper objectMapper;

    @Incoming("appeal_create")
    @Transactional
    @RunOnVirtualThread
    public void onAppealCreateReceived(String message) {
        processMessage(message, "create", appealManagementService::createAppeal);
    }

    @Incoming("appeal_updated")
    @Transactional
    @RunOnVirtualThread
    public void onAppealUpdateReceived(String message) {
        processMessage(message, "update", appealManagementService::updateAppeal);
    }

    private void processMessage(String message, String action, MessageProcessor<AppealManagement> processor) {
        try {
            AppealManagement appealManagement = deserializeMessage(message);
            processor.process(appealManagement);
            log.info(String.format("Appeal %s action processed successfully: %s", action, message));
        } catch (Exception e) {
            log.log(Level.SEVERE, String.format("Error processing %s appeal message: %s", action, message), e);
            throw new RuntimeException(String.format("Failed to process %s appeal message", action), e);
        }
    }

    private AppealManagement deserializeMessage(String message) {
        try {
            return objectMapper.readValue(message, AppealManagement.class);
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
