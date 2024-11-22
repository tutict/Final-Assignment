package finalassignmentbackend.kafkaListener;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.oracle.svm.core.annotate.Inject;
import finalassignmentbackend.entity.SystemLogs;
import finalassignmentbackend.service.SystemLogsService;
import io.vertx.core.Future;
import jakarta.enterprise.context.ApplicationScoped;
import org.eclipse.microprofile.reactive.messaging.Incoming;
import org.jboss.logging.Logger;

@ApplicationScoped
public class SystemLogsKafkaListener {

    private static final Logger log = Logger.getLogger(SystemLogsKafkaListener.class);

    @Inject
    SystemLogsService systemLogsService;

    @Inject
    ObjectMapper objectMapper;

    @Incoming("system_create")
    public void onSystemLogCreateReceived(String message) {
        Future.<Void>future(promise -> {
            try {
                SystemLogs systemLog = deserializeMessage(message);
                systemLogsService.createSystemLog(systemLog);
                promise.complete();
            } catch (Exception e) {
                log.errorf("Error processing create system log message: %s", message, e);
                promise.fail(e);
            }
        }).onComplete(res -> {
            if (res.failed()) {
                log.errorf("Error processing create system log message: %s", message, res.cause());
            }
        });
    }

    @Incoming("system_update")
    public void onSystemLogUpdateReceived(String message) {
        Future.<Void>future(promise -> {
            try {
                SystemLogs systemLog = deserializeMessage(message);
                systemLogsService.updateSystemLog(systemLog);
                promise.complete();
            } catch (Exception e) {
                log.errorf("Error processing update system log message: %s", message, e);
                promise.fail(e);
            }
        }).onComplete(res -> {
            if (res.failed()) {
                log.errorf("Error processing update system log message: %s", message, res.cause());
            }
        });
    }

    private SystemLogs deserializeMessage(String message) {
        try {
            return objectMapper.readValue(message, SystemLogs.class);
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
    }
}
