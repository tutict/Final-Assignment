package finalassignmentbackend.KafkaListener;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import finalassignmentbackend.entity.AppealManagement;
import finalassignmentbackend.service.AppealManagementService;
import io.smallrye.reactive.messaging.annotations.Blocking;
import io.vertx.core.Future;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import org.eclipse.microprofile.reactive.messaging.Acknowledgment;
import org.eclipse.microprofile.reactive.messaging.Incoming;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;


@ApplicationScoped
public class AppealManagementKafkaListener {

    private static final Logger log = LoggerFactory.getLogger(AppealManagementKafkaListener.class);
    private final AppealManagementService appealManagementService;
    private final ObjectMapper objectMapper = new ObjectMapper();

    @Inject
    public AppealManagementKafkaListener(AppealManagementService appealManagementService) {
        this.appealManagementService = appealManagementService;
    }

    @Incoming("appeal_create")
    @Blocking
    public void onAppealCreateReceived(String message, Acknowledgment acknowledgment) {
        Future.<Void>future(promise -> {
            try {
                AppealManagement appealManagement = deserializeMessage(message);
                appealManagementService.createAppeal(appealManagement);
                promise.complete();
            } catch (Exception e) {
                log.error("Error processing create appeal message: {}", message, e);
                promise.fail(e);
            }
        }).onComplete(res -> {
            if (res.succeeded()) {
                acknowledgment.acknowledge();
            } else {
                log.error("Error processing create appeal message: {}", message, res.cause());
            }
        });
    }

    @Incoming("appeal_updated")
    @Blocking
    public void onAppealUpdateReceived(String message, Acknowledgment acknowledgment) {
        Future.<Void>future(promise -> {
            try {
                AppealManagement appealManagement = deserializeMessage(message);
                appealManagementService.updateAppeal(appealManagement);
                promise.complete();
            } catch (Exception e) {
                log.error("Error processing update appeal message: {}", message, e);
                promise.fail(e);
            }
        }).onComplete(res -> {
            if (res.succeeded()) {
                acknowledgment.acknowledge();
            } else {
                log.error("Error processing update appeal message: {}", message, res.cause());
            }
        });
    }

    private AppealManagement deserializeMessage(String message) throws JsonProcessingException {
        return objectMapper.readValue(message, AppealManagement.class);
    }
}
