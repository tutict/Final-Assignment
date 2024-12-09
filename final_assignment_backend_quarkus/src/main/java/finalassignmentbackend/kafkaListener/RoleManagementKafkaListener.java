package finalassignmentbackend.kafkaListener;

import com.fasterxml.jackson.databind.ObjectMapper;
import finalassignmentbackend.entity.RoleManagement;
import finalassignmentbackend.service.RoleManagementService;
import io.smallrye.common.annotation.RunOnVirtualThread;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.transaction.Transactional;
import org.eclipse.microprofile.reactive.messaging.Incoming;

import java.util.logging.Level;
import java.util.logging.Logger;

@ApplicationScoped
public class RoleManagementKafkaListener {

    private static final Logger log = Logger.getLogger(RoleManagementKafkaListener.class.getName());

    @Inject
    RoleManagementService roleManagementService;

    @Inject
    ObjectMapper objectMapper;

    @Incoming("role_create")
    @Transactional
    @RunOnVirtualThread
    public void onRoleCreateReceived(String message) {
        processMessage(message, "create", roleManagementService::createRole);
    }

    @Incoming("role_update")
    @Transactional
    @RunOnVirtualThread
    public void onRoleUpdateReceived(String message) {
        processMessage(message, "update", roleManagementService::updateRole);
    }

    private void processMessage(String message, String action, MessageProcessor<RoleManagement> processor) {
        try {
            RoleManagement role = deserializeMessage(message);
            processor.process(role);
            log.info(String.format("Role %s action processed successfully: %s", action, message));
        } catch (Exception e) {
            log.log(Level.SEVERE, String.format("Error processing %s role message: %s", action, message), e);
            throw new RuntimeException(String.format("Failed to process %s role message", action), e);
        }
    }

    private RoleManagement deserializeMessage(String message) {
        try {
            return objectMapper.readValue(message, RoleManagement.class);
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
