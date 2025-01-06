package finalassignmentbackend.kafkaListener;

import com.fasterxml.jackson.databind.ObjectMapper;
import finalassignmentbackend.entity.DriverInformation;
import finalassignmentbackend.service.DriverInformationService;
import io.smallrye.common.annotation.RunOnVirtualThread;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.transaction.Transactional;
import org.eclipse.microprofile.reactive.messaging.Incoming;

import java.util.logging.Level;
import java.util.logging.Logger;

@ApplicationScoped
public class DriverInformationKafkaListener {

    private static final Logger log = Logger.getLogger(DriverInformationKafkaListener.class.getName());

    @Inject
    DriverInformationService driverInformationService;

    @Inject
    ObjectMapper objectMapper;

    @Incoming("driver_create")
    @Transactional
    @RunOnVirtualThread
    public void onDriverCreateReceived(String message) {
        processMessage(message, "create", (driverInformation) -> driverInformationService.createDriver(driverInformation));
    }

    @Incoming("driver_update")
    @Transactional
    @RunOnVirtualThread
    public void onDriverUpdateReceived(String message) {
        processMessage(message, "update", (driverInformation) -> driverInformationService.updateDriver(driverInformation));
    }

    private void processMessage(String message, String action, MessageProcessor<DriverInformation> processor) {
        try {
            DriverInformation driverInformation = deserializeMessage(message);
            if ("create".equals(action)) {
                driverInformation.setDriverId(null);
                processor.process(driverInformation);
            }
            log.info(String.format("Driver %s action processed successfully: %s", action, message));
        } catch (Exception e) {
            log.log(Level.SEVERE, String.format("Error processing %s driver message: %s", action, message), e);
            throw new RuntimeException(String.format("Failed to process %s driver message", action), e);
        }
    }

    private DriverInformation deserializeMessage(String message) {
        try {
            return objectMapper.readValue(message, DriverInformation.class);
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
