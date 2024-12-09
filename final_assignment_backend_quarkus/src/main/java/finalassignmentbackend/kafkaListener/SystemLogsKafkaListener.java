package finalassignmentbackend.kafkaListener;

import com.fasterxml.jackson.databind.ObjectMapper;
import finalassignmentbackend.entity.SystemLogs;
import finalassignmentbackend.service.SystemLogsService;
import io.smallrye.common.annotation.RunOnVirtualThread;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.transaction.Transactional;
import org.eclipse.microprofile.reactive.messaging.Incoming;

import java.util.logging.Level;
import java.util.logging.Logger;

@ApplicationScoped
public class SystemLogsKafkaListener {

    private static final Logger log = Logger.getLogger(SystemLogsKafkaListener.class.getName());

    @Inject
    SystemLogsService systemLogsService;

    @Inject
    ObjectMapper objectMapper;

    @Incoming("system_create")
    @Transactional
    @RunOnVirtualThread
    public void onSystemLogCreateReceived(String message) {
        processMessage(message, "create", systemLogsService::createSystemLog);
    }

    @Incoming("system_update")
    @Transactional
    @RunOnVirtualThread
    public void onSystemLogUpdateReceived(String message) {
        processMessage(message, "update", systemLogsService::updateSystemLog);
    }

    private void processMessage(String message, String action, MessageProcessor<SystemLogs> processor) {
        try {
            SystemLogs systemLog = deserializeMessage(message);
            processor.process(systemLog);
            log.info(String.format("System log %s action processed successfully: %s", action, message));
        } catch (Exception e) {
            log.log(Level.SEVERE, String.format("Error processing %s system log message: %s", action, message), e);
            throw new RuntimeException(String.format("Failed to process %s system log message", action), e);
        }
    }

    private SystemLogs deserializeMessage(String message) {
        try {
            return objectMapper.readValue(message, SystemLogs.class);
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
