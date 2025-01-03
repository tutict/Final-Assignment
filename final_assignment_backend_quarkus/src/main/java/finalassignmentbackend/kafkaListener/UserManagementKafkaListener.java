package finalassignmentbackend.kafkaListener;

import com.fasterxml.jackson.databind.ObjectMapper;
import finalassignmentbackend.entity.UserManagement;
import finalassignmentbackend.service.UserManagementService;
import io.smallrye.common.annotation.RunOnVirtualThread;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.transaction.Transactional;
import org.eclipse.microprofile.reactive.messaging.Incoming;

import java.util.logging.Level;
import java.util.logging.Logger;

@ApplicationScoped
public class UserManagementKafkaListener {

    private static final Logger log = Logger.getLogger(UserManagementKafkaListener.class.getName());

    @Inject
    UserManagementService userManagementService;

    @Inject
    ObjectMapper objectMapper;

    @Incoming("user_create")
    @Transactional
    @RunOnVirtualThread
    public void onUserCreateReceived(String message) {
        processMessage(message, "create", userManagementService::createUser);
    }

    @Incoming("user_update")
    @Transactional
    @RunOnVirtualThread
    public void onUserUpdateReceived(String message) {
        processMessage(message, "update", userManagementService::updateUser);
    }

    private void processMessage(String message, String action, MessageProcessor<UserManagement> processor) {
        try {
            UserManagement user = deserializeMessage(message);

            // 如果是 create，则确保 userId 为 null，让数据库自增。
            if ("create".equals(action)) {
                user.setUserId(null);
            }

            processor.process(user);
            log.info(String.format("User %s action processed successfully: %s", action, message));
        } catch (Exception e) {
            log.log(Level.SEVERE, String.format("Error processing %s user message: %s", action, message), e);
            throw new RuntimeException(String.format("Failed to process %s user message", action), e);
        }
    }

    private UserManagement deserializeMessage(String message) {
        try {
            return objectMapper.readValue(message, UserManagement.class);
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
