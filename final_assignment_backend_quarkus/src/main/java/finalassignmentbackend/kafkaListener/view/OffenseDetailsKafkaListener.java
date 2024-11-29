package finalassignmentbackend.kafkaListener.view;

import com.fasterxml.jackson.databind.ObjectMapper;
import finalassignmentbackend.entity.view.OffenseDetails;
import finalassignmentbackend.service.view.OffenseDetailsService;
import io.vertx.core.Future;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import org.eclipse.microprofile.reactive.messaging.Incoming;

import java.util.logging.Level;
import java.util.logging.Logger;

@ApplicationScoped
public class OffenseDetailsKafkaListener {

    private static final Logger log = Logger.getLogger(String.valueOf(OffenseDetailsKafkaListener.class));

    @Inject
    OffenseDetailsService offenseDetailsService;

    @Inject
    ObjectMapper objectMapper;

    @Incoming("offense_details_topic")
    public void onOffenseDetailsReceived(String message) {
        Future.<Void>future(promise -> {
            try {
                OffenseDetails offenseDetails = deserializeMessage(message);
                offenseDetailsService.saveOffenseDetails(offenseDetails);
                promise.complete();
            } catch (Exception e) {
                log.log(Level.SEVERE, String.format("Error processing offense details message: %s", message), e);
            }
        }).onComplete(res -> {
            if (res.failed()) {
                log.log(Level.SEVERE, String.format("Error processing offense details message: %s", message), res.cause());
            }
        });
    }

    private OffenseDetails deserializeMessage(String message) {
        try {
            return objectMapper.readValue(message, OffenseDetails.class);
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
    }
}
