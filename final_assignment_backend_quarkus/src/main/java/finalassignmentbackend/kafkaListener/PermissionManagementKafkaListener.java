package finalassignmentbackend.kafkaListener;

import com.fasterxml.jackson.databind.ObjectMapper;
import finalassignmentbackend.entity.PermissionManagement;
import finalassignmentbackend.service.PermissionManagementService;
import io.smallrye.common.annotation.RunOnVirtualThread;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.transaction.Transactional;
import org.eclipse.microprofile.reactive.messaging.Incoming;

import java.util.logging.Level;
import java.util.logging.Logger;

@ApplicationScoped
public class PermissionManagementKafkaListener {

    private static final Logger log = Logger.getLogger(PermissionManagementKafkaListener.class.getName());

    @Inject
    PermissionManagementService permissionManagementService;

    @Inject
    ObjectMapper objectMapper;

    @Incoming("permission_create")
    @Transactional
    @RunOnVirtualThread
    public void onPermissionCreateReceived(String message) {
        processMessage(message, "create", permissionManagementService::createPermission);
    }

    @Incoming("permission_update")
    @Transactional
    @RunOnVirtualThread
    public void onPermissionUpdateReceived(String message) {
        processMessage(message, "update", permissionManagementService::updatePermission);
    }

    private void processMessage(String message, String action, MessageProcessor<PermissionManagement> processor) {
        try {
            PermissionManagement permission = deserializeMessage(message);
            processor.process(permission);
            log.info(String.format("Permission %s action processed successfully: %s", action, message));
        } catch (Exception e) {
            log.log(Level.SEVERE, String.format("Error processing %s permission message: %s", action, message), e);
            throw new RuntimeException(String.format("Failed to process %s permission message", action), e);
        }
    }

    private PermissionManagement deserializeMessage(String message) {
        try {
            return objectMapper.readValue(message, PermissionManagement.class);
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
