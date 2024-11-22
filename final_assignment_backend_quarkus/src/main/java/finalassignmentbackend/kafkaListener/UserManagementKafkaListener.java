package finalassignmentbackend.kafkaListener;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.oracle.svm.core.annotate.Inject;
import finalassignmentbackend.entity.UserManagement;
import finalassignmentbackend.service.UserManagementService;
import io.vertx.core.Future;
import jakarta.enterprise.context.ApplicationScoped;
import org.eclipse.microprofile.reactive.messaging.Incoming;
import org.jboss.logging.Logger;

@ApplicationScoped
public class UserManagementKafkaListener {

    private static final Logger log = Logger.getLogger(UserManagementKafkaListener.class);

    @Inject
    UserManagementService userManagementService;

    @Inject
    ObjectMapper objectMapper;

    @Incoming("user_create")
    public void onUserCreateReceived(String message) {
        Future.<Void>future(promise -> {
            try {
                UserManagement user = deserializeMessage(message);
                userManagementService.createUser(user);
                promise.complete();
            } catch (Exception e) {
                log.errorf("Error processing create user message: %s", message, e);
                promise.fail(e);
            }
        }).onComplete(res -> {
            if (res.failed()) {
                log.errorf("Error processing create user message: %s", message, res.cause());
            }
        });
    }

    @Incoming("user_update")
    public void onUserUpdateReceived(String message) {
        Future.<Void>future(promise -> {
            try {
                UserManagement user = deserializeMessage(message);
                userManagementService.updateUser(user);
                promise.complete();
            } catch (Exception e) {
                log.errorf("Error processing update user message: %s", message, e);
                promise.fail(e);
            }
        }).onComplete(res -> {
            if (res.failed()) {
                log.errorf("Error processing update user message: %s", message, res.cause());
            }
        });
    }

    private UserManagement deserializeMessage(String message) {
        try {
            return objectMapper.readValue(message, UserManagement.class);
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
    }
}
