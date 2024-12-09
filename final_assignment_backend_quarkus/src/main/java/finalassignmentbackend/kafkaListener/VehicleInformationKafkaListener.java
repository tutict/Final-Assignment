package finalassignmentbackend.kafkaListener;

import com.fasterxml.jackson.databind.ObjectMapper;
import finalassignmentbackend.entity.VehicleInformation;
import finalassignmentbackend.service.VehicleInformationService;
import io.smallrye.common.annotation.RunOnVirtualThread;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.transaction.Transactional;
import org.eclipse.microprofile.reactive.messaging.Incoming;

import java.util.logging.Level;
import java.util.logging.Logger;

@ApplicationScoped
public class VehicleInformationKafkaListener {

    private static final Logger log = Logger.getLogger(VehicleInformationKafkaListener.class.getName());

    @Inject
    VehicleInformationService vehicleInformationService;

    @Inject
    ObjectMapper objectMapper;

    @Incoming("vehicle_create")
    @Transactional
    @RunOnVirtualThread
    public void onVehicleCreateReceived(String message) {
        processMessage(message, "create", vehicleInformationService::createVehicleInformation);
    }

    @Incoming("vehicle_update")
    @Transactional
    @RunOnVirtualThread
    public void onVehicleUpdateReceived(String message) {
        processMessage(message, "update", vehicleInformationService::updateVehicleInformation);
    }

    private void processMessage(String message, String action, MessageProcessor<VehicleInformation> processor) {
        try {
            VehicleInformation vehicleInformation = deserializeMessage(message);
            processor.process(vehicleInformation);
            log.info(String.format("Vehicle %s action processed successfully: %s", action, message));
        } catch (Exception e) {
            log.log(Level.SEVERE, String.format("Error processing %s vehicle information message: %s", action, message), e);
            throw new RuntimeException(String.format("Failed to process %s vehicle information message", action), e);
        }
    }

    private VehicleInformation deserializeMessage(String message) {
        try {
            return objectMapper.readValue(message, VehicleInformation.class);
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
