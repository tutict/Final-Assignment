package finalassignmentbackend.kafkaListener.view;

import com.fasterxml.jackson.databind.ObjectMapper;
import finalassignmentbackend.entity.OffenseDetails;
import finalassignmentbackend.service.view.OffenseDetailsService;
import io.smallrye.common.annotation.RunOnVirtualThread;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.transaction.Transactional;
import org.eclipse.microprofile.reactive.messaging.Incoming;

import java.util.logging.Level;
import java.util.logging.Logger;

@ApplicationScoped
public class OffenseDetailsKafkaListener {

    private static final Logger log = Logger.getLogger(OffenseDetailsKafkaListener.class.getName());

    @Inject
    OffenseDetailsService offenseDetailsService;

    @Inject
    ObjectMapper objectMapper;

    @Incoming("offense_details_topic")
    @Transactional
    @RunOnVirtualThread
    public void onOffenseDetailsReceived(String message) {
        try {
            OffenseDetails offenseDetails = deserializeMessage(message);
            offenseDetailsService.saveOffenseDetails(offenseDetails);
            log.info(String.format("Successfully processed offense details message: %s", message));
        } catch (Exception e) {
            log.log(Level.SEVERE, String.format("Error processing offense details message: %s", message), e);
            throw new RuntimeException("Failed to process offense details message", e);
        }
    }

    private OffenseDetails deserializeMessage(String message) {
        try {
            return objectMapper.readValue(message, OffenseDetails.class);
        } catch (Exception e) {
            log.log(Level.SEVERE, "Failed to deserialize message: " + message, e);
            throw new RuntimeException("Failed to deserialize message", e);
        }
    }
}
