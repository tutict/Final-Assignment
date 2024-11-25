package finalassignmentbackend.kafkaListener;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.oracle.svm.core.annotate.Inject;
import finalassignmentbackend.entity.RoleManagement;
import finalassignmentbackend.service.RoleManagementService;
import io.vertx.core.Future;
import jakarta.enterprise.context.ApplicationScoped;
import org.eclipse.microprofile.reactive.messaging.Incoming;

import java.util.logging.Level;
import java.util.logging.Logger;

@ApplicationScoped
public class RoleManagementKafkaListener {

    private static final Logger log = Logger.getLogger(String.valueOf(RoleManagementKafkaListener.class));

    @Inject
    RoleManagementService roleManagementService;

    @Inject
    ObjectMapper objectMapper;

    @Incoming("role_create")
    public void onRoleCreateReceived(String message) {
        Future.<Void>future(promise -> {
            try {
                RoleManagement role = deserializeMessage(message);
                roleManagementService.createRole(role);
                promise.complete();
            } catch (Exception e) {
                log.log(Level.SEVERE, String.format("Error processing create role message: %s", message), e);
            }
        }).onComplete(res -> {
            if (res.failed()) {
                log.log(Level.SEVERE, String.format("Error processing create role message: %s", message), res.cause());
            }
        });
    }

    @Incoming("role_update")
    public void onRoleUpdateReceived(String message) {
        Future.<Void>future(promise -> {
            try {
                RoleManagement role = deserializeMessage(message);
                roleManagementService.updateRole(role);
                promise.complete();
            } catch (Exception e) {
                log.log(Level.SEVERE, String.format("Error processing update role message: %s", message), e);
            }
        }).onComplete(res -> {
            if (res.failed()) {
                log.log(Level.SEVERE, String.format("Error processing update role message: %s", message), res.cause());
            }
        });
    }

    private RoleManagement deserializeMessage(String message) {
        try {
            return objectMapper.readValue(message, RoleManagement.class);
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
    }
}
