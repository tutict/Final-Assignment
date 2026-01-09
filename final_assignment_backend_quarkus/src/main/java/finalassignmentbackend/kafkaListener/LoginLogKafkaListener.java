package finalassignmentbackend.kafkaListener;

import com.fasterxml.jackson.databind.ObjectMapper;
import finalassignmentbackend.entity.AuditLoginLog;
import finalassignmentbackend.service.AuditLoginLogService;
import io.smallrye.common.annotation.RunOnVirtualThread;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.transaction.Transactional;
import org.eclipse.microprofile.reactive.messaging.Incoming;

import java.util.logging.Level;
import java.util.logging.Logger;

// Kafka listener for login audit messages (new schema)
@ApplicationScoped
public class LoginLogKafkaListener {

    private static final Logger log = Logger.getLogger(LoginLogKafkaListener.class.getName());

    @Inject
    AuditLoginLogService auditLoginLogService;

    @Inject
    ObjectMapper objectMapper;

    @Incoming("login_create")
    @Transactional
    @RunOnVirtualThread
    public void onLoginLogCreateReceived(String message) {
        log.log(Level.INFO, "Received Kafka create message: {0}", message);
        processMessage(message, "create", auditLoginLogService::createAuditLoginLog);
    }

    @Incoming("login_update")
    @Transactional
    @RunOnVirtualThread
    public void onLoginLogUpdateReceived(String message) {
        log.log(Level.INFO, "Received Kafka update message: {0}", message);
        processMessage(message, "update", auditLoginLogService::updateAuditLoginLog);
    }

    private void processMessage(String message, String action, MessageProcessor<AuditLoginLog> processor) {
        try {
            AuditLoginLog logRecord = deserializeMessage(message);
            if ("create".equals(action)) {
                logRecord.setLogId(null);
            }
            processor.process(logRecord);
            log.info(String.format("Login audit %s processed: %s", action, logRecord));
        } catch (Exception e) {
            log.log(Level.SEVERE, String.format("Failed to process login audit %s message: %s", action, message), e);
            throw new RuntimeException(String.format("Failed to process login audit %s message", action), e);
        }
    }

    private AuditLoginLog deserializeMessage(String message) {
        try {
            return objectMapper.readValue(message, AuditLoginLog.class);
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
