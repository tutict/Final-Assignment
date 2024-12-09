package finalassignmentbackend.kafkaListener;

import com.fasterxml.jackson.databind.ObjectMapper;
import finalassignmentbackend.entity.OperationLog;
import finalassignmentbackend.service.OperationLogService;
import io.smallrye.common.annotation.RunOnVirtualThread;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.transaction.Transactional;
import org.eclipse.microprofile.reactive.messaging.Incoming;

import java.util.logging.Level;
import java.util.logging.Logger;

@ApplicationScoped
public class OperationLogKafkaListener {

    private static final Logger log = Logger.getLogger(OperationLogKafkaListener.class.getName());

    @Inject
    OperationLogService operationLogService;

    @Inject
    ObjectMapper objectMapper;

    @Incoming("operation_create")
    @Transactional
    @RunOnVirtualThread
    public void onOperationLogCreateReceived(String message) {
        processMessage(message, "create", operationLogService::createOperationLog);
    }

    @Incoming("operation_update")
    @Transactional
    @RunOnVirtualThread
    public void onOperationLogUpdateReceived(String message) {
        processMessage(message, "update", operationLogService::updateOperationLog);
    }

    private void processMessage(String message, String action, MessageProcessor<OperationLog> processor) {
        try {
            OperationLog operationLog = deserializeMessage(message);
            processor.process(operationLog);
            log.info(String.format("Operation log %s action processed successfully: %s", action, message));
        } catch (Exception e) {
            log.log(Level.SEVERE, String.format("Error processing %s operation log message: %s", action, message), e);
            throw new RuntimeException(String.format("Failed to process %s operation log message", action), e);
        }
    }

    private OperationLog deserializeMessage(String message) {
        try {
            return objectMapper.readValue(message, OperationLog.class);
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
