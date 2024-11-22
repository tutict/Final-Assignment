package finalassignmentbackend.kafkaListener;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.oracle.svm.core.annotate.Inject;
import finalassignmentbackend.entity.SystemSettings;
import finalassignmentbackend.service.SystemSettingsService;
import io.vertx.core.Future;
import jakarta.enterprise.context.ApplicationScoped;
import org.eclipse.microprofile.reactive.messaging.Incoming;
import org.jboss.logging.Logger;

@ApplicationScoped
public class SystemSettingsKafkaListener {

    private static final Logger log = Logger.getLogger(SystemSettingsKafkaListener.class);

    @Inject
    SystemSettingsService systemSettingsService;

    @Inject
    ObjectMapper objectMapper;

    @Incoming("system_settings_update")
    public void onSystemSettingsUpdateReceived(String message) {
        Future.<Void>future(promise -> {
            try {
                SystemSettings systemSettings = deserializeMessage(message);
                systemSettingsService.updateSystemSettings(systemSettings);
                promise.complete();
            } catch (Exception e) {
                log.errorf("Error processing update system settings message: %s", message, e);
                promise.fail(e);
            }
        }).onComplete(res -> {
            if (res.failed()) {
                log.errorf("Error processing update system settings message: %s", message, res.cause());
            }
        });
    }

    private SystemSettings deserializeMessage(String message) {
        try {
            return objectMapper.readValue(message, SystemSettings.class);
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
    }
}
