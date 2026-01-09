package finalassignmentbackend.kafkaListener;

import com.fasterxml.jackson.databind.ObjectMapper;
import finalassignmentbackend.entity.SysPermission;
import finalassignmentbackend.service.SysPermissionService;
import io.smallrye.common.annotation.RunOnVirtualThread;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.transaction.Transactional;
import org.eclipse.microprofile.reactive.messaging.Incoming;

import java.util.logging.Level;
import java.util.logging.Logger;

// Kafka listener for permission messages (new schema)
@ApplicationScoped
public class PermissionManagementKafkaListener {

    private static final Logger log = Logger.getLogger(PermissionManagementKafkaListener.class.getName());

    @Inject
    SysPermissionService sysPermissionService;

    @Inject
    ObjectMapper objectMapper;

    @Incoming("permission_create")
    @Transactional
    @RunOnVirtualThread
    public void onPermissionCreateReceived(String message) {
        log.log(Level.INFO, "Received Kafka create message: {0}", message);
        processMessage(message, "create", sysPermissionService::createSysPermission);
    }

    @Incoming("permission_update")
    @Transactional
    @RunOnVirtualThread
    public void onPermissionUpdateReceived(String message) {
        log.log(Level.INFO, "Received Kafka update message: {0}", message);
        processMessage(message, "update", sysPermissionService::updateSysPermission);
    }

    private void processMessage(String message, String action, MessageProcessor<SysPermission> processor) {
        try {
            SysPermission permission = deserializeMessage(message);
            if ("create".equals(action)) {
                permission.setPermissionId(null);
            }
            processor.process(permission);
            log.info(String.format("Permission %s processed: %s", action, permission));
        } catch (Exception e) {
            log.log(Level.SEVERE, String.format("Failed to process permission %s message: %s", action, message), e);
            throw new RuntimeException(String.format("Failed to process permission %s message", action), e);
        }
    }

    private SysPermission deserializeMessage(String message) {
        try {
            return objectMapper.readValue(message, SysPermission.class);
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
