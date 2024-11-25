package finalassignmentbackend.kafkaListener;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.oracle.svm.core.annotate.Inject;
import finalassignmentbackend.entity.OperationLog;
import finalassignmentbackend.service.OperationLogService;
import io.vertx.core.Future;
import jakarta.enterprise.context.ApplicationScoped;
import org.eclipse.microprofile.reactive.messaging.Incoming;

import java.util.logging.Level;
import java.util.logging.Logger;

@ApplicationScoped
public class OperationLogKafkaListener {

    private static final Logger log = Logger.getLogger(String.valueOf(OperationLogKafkaListener.class));

    @Inject
    OperationLogService operationLogService;

    @Inject
    ObjectMapper objectMapper;

    @Incoming("operation_create")
    public void onOperationLogCreateReceived(String message) {
        Future.<Void>future(promise -> {
            try {
                OperationLog operationLog = deserializeMessage(message);
                operationLogService.createOperationLog(operationLog);
                promise.complete();
            } catch (Exception e) {
                log.log(Level.SEVERE, String.format("Error processing create operation log message: %s", message), e);
            }
        }).onComplete(res -> {
            if (res.failed()) {
                log.log(Level.SEVERE, String.format("Error processing create operation log message: %s", message), res.cause());
            }
        });
    }

    @Incoming("operation_update")
    public void onOperationLogUpdateReceived(String message) {
        Future.<Void>future(promise -> {
            try {
                OperationLog operationLog = deserializeMessage(message);
                operationLogService.updateOperationLog(operationLog);
                promise.complete();
            } catch (Exception e) {
                log.log(Level.SEVERE, String.format("Error processing update operation log message: %s", message), e);
            }
        }).onComplete(res -> {
            if (res.failed()) {
                log.log(Level.SEVERE, String.format("Error processing update operation log message: %s", message), res.cause());
            }
        });
    }

    private OperationLog deserializeMessage(String message) {
        try {
            return objectMapper.readValue(message, OperationLog.class);
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
    }
}
