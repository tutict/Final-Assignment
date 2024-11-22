package finalassignmentbackend.kafkaListener;

import com.fasterxml.jackson.databind.ObjectMapper;
import finalassignmentbackend.entity.AppealManagement;
import finalassignmentbackend.service.AppealManagementService;
import io.smallrye.reactive.messaging.annotations.Blocking;
import io.vertx.core.Future;
import jakarta.enterprise.context.ApplicationScoped;
import org.eclipse.microprofile.reactive.messaging.Incoming;
import org.jboss.logging.Logger;

@ApplicationScoped
public class AppealManagementKafkaListener {

    private static final Logger log = Logger.getLogger(AppealManagementKafkaListener.class);
    private final AppealManagementService appealManagementService;
    private final ObjectMapper objectMapper = new ObjectMapper().findAndRegisterModules();

    public AppealManagementKafkaListener(AppealManagementService appealManagementService) {
        this.appealManagementService = appealManagementService;
    }

    @Incoming("appeal_create")
    @Blocking
    public void onAppealCreateReceived(String message) {
        Future.<Void>future(promise -> {
            try {
                AppealManagement appealManagement = deserializeMessage(message);
                appealManagementService.createAppeal(appealManagement);
                promise.complete();
            } catch (Exception e) {
                log.errorf("Error processing create appeal message: %s", message, e);
                promise.fail(e);
            }
        }).onComplete(res -> {
            if (res.failed()) {
                log.errorf("Error processing create appeal message: %s", message, res.cause());
            }
        });
    }

    @Incoming("appeal_updated")
    @Blocking
    public void onAppealUpdateReceived(String message) {
        Future.<Void>future(promise -> {
            try {
                AppealManagement appealManagement = deserializeMessage(message);
                appealManagementService.updateAppeal(appealManagement);
                promise.complete();
            } catch (Exception e) {
                log.errorf("Error processing update appeal message: %s", message, e);
                promise.fail(e);
            }
        }).onComplete(res -> {
            if (res.failed()) {
                log.errorf("Error processing update appeal message: %s", message, res.cause());
            }
        });
    }

    private AppealManagement deserializeMessage(String message) {
        try {
            return objectMapper.readValue(message, AppealManagement.class);
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
    }
}
