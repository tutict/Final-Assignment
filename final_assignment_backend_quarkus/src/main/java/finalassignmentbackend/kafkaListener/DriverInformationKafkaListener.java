package finalassignmentbackend.kafkaListener;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.oracle.svm.core.annotate.Inject;
import finalassignmentbackend.entity.DriverInformation;
import finalassignmentbackend.service.DriverInformationService;
import io.vertx.core.Future;
import jakarta.enterprise.context.ApplicationScoped;
import org.eclipse.microprofile.reactive.messaging.Incoming;

import java.util.logging.Level;
import java.util.logging.Logger;

@ApplicationScoped
public class DriverInformationKafkaListener {

    private static final Logger log = Logger.getLogger(String.valueOf(DriverInformationKafkaListener.class));

    @Inject
    DriverInformationService driverInformationService;

    @Inject
    ObjectMapper objectMapper;

    @Incoming("driver_create")
    public void onDriverCreateReceived(String message) {
        Future.<Void>future(promise -> {
            try {
                DriverInformation driverInformation = deserializeMessage(message);
                driverInformationService.createDriver(driverInformation);
                promise.complete();
            } catch (Exception e) {
                log.log(Level.SEVERE, String.format("Error processing create driver message: %s", message), e);
            }
        }).onComplete(res -> {
            if (res.failed()) {
                log.log(Level.SEVERE, String.format("Error processing create driver message: %s", message), res.cause());
            }
        });
    }

    @Incoming("driver_update")
    public void onDriverUpdateReceived(String message) {
        Future.<Void>future(promise -> {
            try {
                DriverInformation driverInformation = deserializeMessage(message);
                driverInformationService.updateDriver(driverInformation);
                promise.complete();
            } catch (Exception e) {
                log.log(Level.SEVERE, String.format("Error processing update driver message: %s", message), e);
            }
        }).onComplete(res -> {
            if (res.failed()) {
                log.log(Level.SEVERE, String.format("Error processing update driver message: %s", message), res.cause());
            }
        });
    }

    private DriverInformation deserializeMessage(String message) {
        try {
            return objectMapper.readValue(message, DriverInformation.class);
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
    }
}
