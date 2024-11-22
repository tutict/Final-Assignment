package finalassignmentbackend.kafkaListener;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.oracle.svm.core.annotate.Inject;
import finalassignmentbackend.entity.PermissionManagement;
import finalassignmentbackend.service.PermissionManagementService;
import io.vertx.core.Future;
import jakarta.enterprise.context.ApplicationScoped;
import org.eclipse.microprofile.reactive.messaging.Incoming;
import org.jboss.logging.Logger;

@ApplicationScoped
public class PermissionManagementKafkaListener {

    private static final Logger log = Logger.getLogger(PermissionManagementKafkaListener.class);

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
                log.errorf("Error processing create permission message: %s", message, e);
                promise.fail(e);
            }
        }).onComplete(res -> {
            if (res.failed()) {
                log.errorf("Error processing create permission message: %s", message, res.cause());
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
                log.errorf("Error processing update permission message: %s", message, e);
                promise.fail(e);
            }
        }).onComplete(res -> {
            if (res.failed()) {
                log.errorf("Error processing update permission message: %s", message, res.cause());
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
