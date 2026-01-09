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

// Kafka listener for system log messages mapped to operation audit (new schema)
@ApplicationScoped
public class SystemLogsKafkaListener {

    private static final Logger log = Logger.getLogger(SystemLogsKafkaListener.class.getName());

    @Inject
    AuditOperationLogService auditOperationLogService;

    @Inject
    ObjectMapper objectMapper;

    @Incoming("system_create")
    @Transactional
    @RunOnVirtualThread
    public void onSystemLogCreateReceived(String message) {
        log.log(Level.INFO, "Received Kafka create message: {0}", message);
        processMessage(message, "create", auditOperationLogService::createAuditOperationLog);
    }

    @Incoming("system_update")
    @Transactional
    @RunOnVirtualThread
    public void onSystemLogUpdateReceived(String message) {
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
            log.info(String.format("System log %s processed: %s", action, logRecord));
        } catch (Exception e) {
            log.log(Level.SEVERE, String.format("Failed to process system log %s message: %s", action, message), e);
            throw new RuntimeException(String.format("Failed to process system log %s message", action), e);
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
