package finalassignmentbackend.kafkaListener;

import com.fasterxml.jackson.databind.ObjectMapper;
import finalassignmentbackend.entity.AuditOperationLog;
import finalassignmentbackend.service.AuditOperationLogService;
import io.smallrye.common.annotation.RunOnVirtualThread;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.transaction.Transactional;
import org.eclipse.microprofile.reactive.messaging.Incoming;

import java.util.logging.Level;
import java.util.logging.Logger;

// Kafka listener for operation audit messages (new schema)
@ApplicationScoped
public class OperationLogKafkaListener {

    private static final Logger log = Logger.getLogger(OperationLogKafkaListener.class.getName());

    @Inject
    AuditOperationLogService auditOperationLogService;

    @Inject
    ObjectMapper objectMapper;

    @Incoming("operation_create")
    @Transactional
    @RunOnVirtualThread
    public void onOperationLogCreateReceived(String message) {
        log.log(Level.INFO, "Received Kafka create message: {0}", message);
        processMessage(message, "create", auditOperationLogService::createAuditOperationLog);
    }

    @Incoming("operation_update")
    @Transactional
    @RunOnVirtualThread
    public void onOperationLogUpdateReceived(String message) {
        log.log(Level.INFO, "Received Kafka update message: {0}", message);
        processMessage(message, "update", auditOperationLogService::updateAuditOperationLog);
    }

    private void processMessage(String message, String action, MessageProcessor<AuditOperationLog> processor) {
        try {
            AuditOperationLog logRecord = deserializeMessage(message);
            if ("create".equals(action)) {
                logRecord.setLogId(null);
            }
            processor.process(logRecord);
            log.info(String.format("Operation audit %s processed: %s", action, logRecord));
        } catch (Exception e) {
            log.log(Level.SEVERE, String.format("Failed to process operation audit %s message: %s", action, message), e);
            throw new RuntimeException(String.format("Failed to process operation audit %s message", action), e);
        }
    }

    private AuditOperationLog deserializeMessage(String message) {
        try {
            return objectMapper.readValue(message, AuditOperationLog.class);
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
