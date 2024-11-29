package finalassignmentbackend.kafkaListener;

import com.fasterxml.jackson.databind.ObjectMapper;
import finalassignmentbackend.entity.PermissionManagement;
import finalassignmentbackend.service.PermissionManagementService;
import io.vertx.core.Future;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import org.eclipse.microprofile.reactive.messaging.Incoming;

import java.util.logging.Level;
import java.util.logging.Logger;

@ApplicationScoped
public class PermissionManagementKafkaListener {

    private static final Logger log = Logger.getLogger(String.valueOf(PermissionManagementKafkaListener.class));

    @Inject
    PermissionManagementService permissionManagementService;

    @Inject
    ObjectMapper objectMapper;

    @Incoming("permission_create")
    public void onPermissionCreateReceived(String message) {
        Future.<Void>future(promise -> {
            try {
                PermissionManagement permission = deserializeMessage(message);
                permissionManagementService.createPermission(permission);
                promise.complete();
            } catch (Exception e) {
                log.log(Level.SEVERE, String.format("Error processing create permission message: %s", message), e);
            }
        }).onComplete(res -> {
            if (res.failed()) {
                log.log(Level.SEVERE, String.format("error processing create permission message: %s", message), res.cause());
            }
        });
    }

    @Incoming("permission_update")
    public void onPermissionUpdateReceived(String message) {
        Future.<Void>future(promise -> {
            try {
                PermissionManagement permission = deserializeMessage(message);
                permissionManagementService.updatePermission(permission);
                promise.complete();
            } catch (Exception e) {
                log.log(Level.SEVERE, String.format("Error processing update permission message: %s", message), e);
            }
        }).onComplete(res -> {
            if (res.failed()) {
                log.log(Level.SEVERE, String.format("error processing update permission message: %s", message), res.cause());
            }
        });
    }

    private PermissionManagement deserializeMessage(String message) {
        try {
            return objectMapper.readValue(message, PermissionManagement.class);
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
    }
}
