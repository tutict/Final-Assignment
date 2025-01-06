package finalassignmentbackend.kafkaListener;

import com.fasterxml.jackson.databind.ObjectMapper;
import finalassignmentbackend.entity.OffenseInformation;
import finalassignmentbackend.service.OffenseInformationService;
import io.smallrye.common.annotation.RunOnVirtualThread;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.transaction.Transactional;
import org.eclipse.microprofile.reactive.messaging.Incoming;

import java.util.logging.Level;
import java.util.logging.Logger;

@ApplicationScoped
public class OffenseInformationKafkaListener {

    private static final Logger log = Logger.getLogger(OffenseInformationKafkaListener.class.getName());

    @Inject
    OffenseInformationService offenseInformationService;

    @Inject
    ObjectMapper objectMapper;

    @Incoming("offense_create")
    @Transactional
    @RunOnVirtualThread
    public void onOffenseCreateReceived(String message) {
        processMessage(message, "create", (offenseInformation) -> offenseInformationService.createOffense(offenseInformation));
    }

    @Incoming("offense_update")
    @Transactional
    @RunOnVirtualThread
    public void onOffenseUpdateReceived(String message) {
        processMessage(message, "update", (offenseInformation) -> offenseInformationService.updateOffense(offenseInformation));
    }

    private void processMessage(String message, String action, MessageProcessor<OffenseInformation> processor) {
        try {
            OffenseInformation offenseInformation = deserializeMessage(message);
            if ("create".equals(action)) {
                offenseInformation.setOffenseId(null);
                processor.process(offenseInformation);
            }
            log.info(String.format("Offense %s action processed successfully: %s", action, message));
        } catch (Exception e) {
            log.log(Level.SEVERE, String.format("Error processing %s offense message: %s", action, message), e);
            throw new RuntimeException(String.format("Failed to process %s offense message", action), e);
        }
    }

    private OffenseInformation deserializeMessage(String message) {
        try {
            return objectMapper.readValue(message, OffenseInformation.class);
        } catch (Exception e) {
            log.log(Level.SEVERE, "Failed to deserialize message: " + message, e);
            throw new RuntimeException("Failed to deserialize message", e);
        }
    }

    @FunctionalInterface
    private interface MessageProcessor<T> {
        void process(T t) throws Exception;
    }
}
