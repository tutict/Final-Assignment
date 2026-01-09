package finalassignmentbackend.kafkaListener;

import com.fasterxml.jackson.databind.ObjectMapper;
import finalassignmentbackend.entity.AppealRecord;
import finalassignmentbackend.service.AppealManagementService;
import io.smallrye.common.annotation.RunOnVirtualThread;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.transaction.Transactional;
import org.eclipse.microprofile.reactive.messaging.Incoming;

import java.util.logging.Level;
import java.util.logging.Logger;

// Kafka listener for appeal record messages (new schema)
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
        log.log(Level.INFO, "Received Kafka create message: {0}", message);
        processMessage(message, "create", appealManagementService::createAppeal);
    }

    @Incoming("appeal_update")
    @Transactional
    @RunOnVirtualThread
    public void onAppealUpdateReceived(String message) {
        log.log(Level.INFO, "Received Kafka update message: {0}", message);
        processMessage(message, "update", appealManagementService::updateAppeal);
    }

    private void processMessage(String message, String action, MessageProcessor<AppealRecord> processor) {
        try {
            AppealRecord record = deserializeMessage(message);
            if ("create".equals(action)) {
                record.setAppealId(null);
            }
            processor.process(record);
            log.info(String.format("Appeal %s processed: %s", action, record));
        } catch (Exception e) {
            log.log(Level.SEVERE, String.format("Failed to process appeal %s message: %s", action, message), e);
            throw new RuntimeException(String.format("Failed to process appeal %s message", action), e);
        }
    }

    private AppealRecord deserializeMessage(String message) {
        try {
            return objectMapper.readValue(message, AppealRecord.class);
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
