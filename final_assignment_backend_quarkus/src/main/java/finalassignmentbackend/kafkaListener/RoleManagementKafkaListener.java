package finalassignmentbackend.kafkaListener;

import com.fasterxml.jackson.databind.ObjectMapper;
import finalassignmentbackend.entity.SysRole;
import finalassignmentbackend.service.SysRoleService;
import io.smallrye.common.annotation.RunOnVirtualThread;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.transaction.Transactional;
import org.eclipse.microprofile.reactive.messaging.Incoming;

import java.util.logging.Level;
import java.util.logging.Logger;

// Kafka listener for role messages (new schema)
@ApplicationScoped
public class RoleManagementKafkaListener {

    private static final Logger log = Logger.getLogger(RoleManagementKafkaListener.class.getName());

    @Inject
    SysRoleService sysRoleService;

    @Inject
    ObjectMapper objectMapper;

    @Incoming("role_create")
    @Transactional
    @RunOnVirtualThread
    public void onRoleCreateReceived(String message) {
        log.log(Level.INFO, "Received Kafka create message: {0}", message);
        processMessage(message, "create", sysRoleService::createSysRole);
    }

    @Incoming("role_update")
    @Transactional
    @RunOnVirtualThread
    public void onRoleUpdateReceived(String message) {
        log.log(Level.INFO, "Received Kafka update message: {0}", message);
        processMessage(message, "update", sysRoleService::updateSysRole);
    }

    private void processMessage(String message, String action, MessageProcessor<SysRole> processor) {
        try {
            SysRole role = deserializeMessage(message);
            if ("create".equals(action)) {
                role.setRoleId(null);
            }
            processor.process(role);
            log.info(String.format("Role %s processed: %s", action, role));
        } catch (Exception e) {
            log.log(Level.SEVERE, String.format("Failed to process role %s message: %s", action, message), e);
            throw new RuntimeException(String.format("Failed to process role %s message", action), e);
        }
    }

    private SysRole deserializeMessage(String message) {
        try {
            return objectMapper.readValue(message, SysRole.class);
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
