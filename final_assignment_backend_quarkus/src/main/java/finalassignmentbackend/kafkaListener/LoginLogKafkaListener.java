package finalassignmentbackend.kafkaListener;

import com.fasterxml.jackson.databind.ObjectMapper;
import finalassignmentbackend.entity.LoginLog;
import finalassignmentbackend.service.LoginLogService;
import io.vertx.core.Future;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import org.eclipse.microprofile.reactive.messaging.Incoming;

import java.util.logging.Level;
import java.util.logging.Logger;

@ApplicationScoped
public class LoginLogKafkaListener {

    private static final Logger log = Logger.getLogger(String.valueOf(LoginLogKafkaListener.class));

    @Inject
    LoginLogService loginLogService;

    @Inject
    ObjectMapper objectMapper;

    @Incoming("login_create")
    public void onLoginLogCreateReceived(String message) {
        Future.<Void>future(promise -> {
            try {
                LoginLog loginLog = deserializeMessage(message);
                loginLogService.createLoginLog(loginLog);
                promise.complete();
            } catch (Exception e) {
                log.log(Level.SEVERE, String.format("Error processing create login log message: %s", message), e);
            }
        }).onComplete(res -> {
            if (res.failed()) {
                log.log(Level.SEVERE, String.format("Error processing create login log message: %s", message), res.cause());
            }
        });
    }

    @Incoming("login_update")
    public void onLoginLogUpdateReceived(String message) {
        Future.<Void>future(promise -> {
            try {
                LoginLog loginLog = deserializeMessage(message);
                loginLogService.updateLoginLog(loginLog);
                promise.complete();
            } catch (Exception e) {
                log.log(Level.SEVERE, String.format("Error processing update login log message: %s", message), e);
            }
        }).onComplete(res -> {
            if (res.failed()) {
                log.log(Level.SEVERE, String.format("Error processing update login log message: %s", message), res.cause());
            }
        });
    }

    private LoginLog deserializeMessage(String message) {
        try {
            return objectMapper.readValue(message, LoginLog.class);
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
    }
}
