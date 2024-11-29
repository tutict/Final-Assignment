package finalassignmentbackend.kafkaListener;

import com.fasterxml.jackson.databind.ObjectMapper;
import finalassignmentbackend.entity.OffenseInformation;
import finalassignmentbackend.service.OffenseInformationService;
import io.vertx.core.Future;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import org.eclipse.microprofile.reactive.messaging.Incoming;

import java.util.logging.Level;
import java.util.logging.Logger;

@ApplicationScoped
public class OffenseInformationKafkaListener {

    private static final Logger log = Logger.getLogger(String.valueOf(OffenseInformationKafkaListener.class));

    @Inject
    OffenseInformationService offenseInformationService;

    @Inject
    ObjectMapper objectMapper;

    @Incoming("offense_create")
    public void onOffenseCreateReceived(String message) {
        Future.<Void>future(promise -> {
            try {
                OffenseInformation offenseInformation = deserializeMessage(message);
                offenseInformationService.createOffense(offenseInformation);
                promise.complete();
            } catch (Exception e) {
                log.log(Level.SEVERE, String.format("Error processing create offense message: %s", message), e);
            }
        }).onComplete(res -> {
            if (res.failed()) {
                log.log(Level.SEVERE, String.format("Error processing create offense message: %s", message), res.cause());
            }
        });
    }

    @Incoming("offense_update")
    public void onOffenseUpdateReceived(String message) {
        Future.<Void>future(promise -> {
            try {
                OffenseInformation offenseInformation = deserializeMessage(message);
                offenseInformationService.updateOffense(offenseInformation);
                promise.complete();
            } catch (Exception e) {
                log.log(Level.SEVERE, String.format("Error processing update offense message: %s", message), e);
            }
        }).onComplete(res -> {
            if (res.failed()) {
                log.log(Level.SEVERE, String.format("Error processing update offense message: %s", message), res.cause());
            }
        });
    }

    private OffenseInformation deserializeMessage(String message) {
        try {
            return objectMapper.readValue(message, OffenseInformation.class);
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
    }
}
