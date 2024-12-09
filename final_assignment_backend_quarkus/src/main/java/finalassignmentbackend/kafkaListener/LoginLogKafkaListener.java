package finalassignmentbackend.kafkaListener;

import com.fasterxml.jackson.databind.ObjectMapper;
import finalassignmentbackend.entity.LoginLog;
import finalassignmentbackend.service.LoginLogService;
import io.smallrye.common.annotation.RunOnVirtualThread;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.transaction.Transactional;
import org.eclipse.microprofile.reactive.messaging.Incoming;

import java.util.logging.Level;
import java.util.logging.Logger;

@ApplicationScoped
public class LoginLogKafkaListener {

    private static final Logger log = Logger.getLogger(LoginLogKafkaListener.class.getName());

    @Inject
    LoginLogService loginLogService;

    @Inject
    ObjectMapper objectMapper;

    @Incoming("login_create")
    @Transactional
    @RunOnVirtualThread
    public void onLoginLogCreateReceived(String message) {
        processMessage(message, "create", loginLogService::createLoginLog);
    }

    @Incoming("login_update")
    @Transactional
    @RunOnVirtualThread
    public void onLoginLogUpdateReceived(String message) {
        processMessage(message, "update", loginLogService::updateLoginLog);
    }

    private void processMessage(String message, String action, MessageProcessor<LoginLog> processor) {
        try {
            LoginLog loginLog = deserializeMessage(message);
            processor.process(loginLog);
            log.info(String.format("Login log %s action processed successfully: %s", action, message));
        } catch (Exception e) {
            log.log(Level.SEVERE, String.format("Error processing %s login log message: %s", action, message), e);
            throw new RuntimeException(String.format("Failed to process %s login log message", action), e);
        }
    }

    private LoginLog deserializeMessage(String message) {
        try {
            return objectMapper.readValue(message, LoginLog.class);
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
