package finalassignmentbackend.kafkaListener;

import com.fasterxml.jackson.databind.ObjectMapper;
import finalassignmentbackend.entity.SystemLogs;
import finalassignmentbackend.service.SystemLogsService;
import io.vertx.core.Future;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import org.eclipse.microprofile.reactive.messaging.Incoming;

import java.util.logging.Level;
import java.util.logging.Logger;

@ApplicationScoped
public class SystemLogsKafkaListener {

    private static final Logger log = Logger.getLogger(String.valueOf(SystemLogsKafkaListener.class));

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
                log.log(Level.SEVERE, String.format("Error processing create system log message: %s", message), e);
            }
        }).onComplete(res -> {
            if (res.failed()) {
                log.log(Level.SEVERE, String.format("Error processing create system log message: %s", message), res.cause());
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
                log.log(Level.SEVERE, String.format("Error processing update system log message: %s", message), e);
            }
        }).onComplete(res -> {
            if (res.failed()) {
                log.log(Level.SEVERE, String.format("Error processing update system log message: %s", message), res.cause());
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
