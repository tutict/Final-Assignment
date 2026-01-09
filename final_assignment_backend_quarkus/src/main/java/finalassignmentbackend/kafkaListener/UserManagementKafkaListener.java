package finalassignmentbackend.kafkaListener;

import com.fasterxml.jackson.databind.ObjectMapper;
import finalassignmentbackend.entity.SysUser;
import finalassignmentbackend.service.SysUserService;
import io.smallrye.common.annotation.RunOnVirtualThread;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.transaction.Transactional;
import org.eclipse.microprofile.reactive.messaging.Incoming;

import java.util.logging.Level;
import java.util.logging.Logger;

// Kafka listener for user messages (new schema)
@ApplicationScoped
public class UserManagementKafkaListener {

    private static final Logger log = Logger.getLogger(UserManagementKafkaListener.class.getName());

    @Inject
    SysUserService sysUserService;

    @Inject
    ObjectMapper objectMapper;

    @Incoming("user_create")
    @Transactional
    @RunOnVirtualThread
    public void onUserCreateReceived(String message) {
        log.log(Level.INFO, "Received Kafka create message: {0}", message);
        processMessage(message, "create", sysUserService::createSysUser);
    }

    @Incoming("user_update")
    @Transactional
    @RunOnVirtualThread
    public void onUserUpdateReceived(String message) {
        log.log(Level.INFO, "Received Kafka update message: {0}", message);
        processMessage(message, "update", sysUserService::updateSysUser);
    }

    private void processMessage(String message, String action, MessageProcessor<SysUser> processor) {
        try {
            SysUser user = deserializeMessage(message);
            if ("create".equals(action)) {
                user.setUserId(null);
            }
            processor.process(user);
            log.info(String.format("User %s processed: %s", action, user));
        } catch (Exception e) {
            log.log(Level.SEVERE, String.format("Failed to process user %s message: %s", action, message), e);
            throw new RuntimeException(String.format("Failed to process user %s message", action), e);
        }
    }

    private SysUser deserializeMessage(String message) {
        try {
            return objectMapper.readValue(message, SysUser.class);
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
