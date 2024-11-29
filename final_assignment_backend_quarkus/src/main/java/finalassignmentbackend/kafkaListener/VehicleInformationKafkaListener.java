package finalassignmentbackend.kafkaListener;

import com.fasterxml.jackson.databind.ObjectMapper;
import finalassignmentbackend.entity.VehicleInformation;
import finalassignmentbackend.service.VehicleInformationService;
import io.vertx.core.Future;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import org.eclipse.microprofile.reactive.messaging.Incoming;

import java.util.logging.Level;
import java.util.logging.Logger;

@ApplicationScoped
public class VehicleInformationKafkaListener {

    private static final Logger log = Logger.getLogger(String.valueOf(VehicleInformationKafkaListener.class));

    @Inject
    VehicleInformationService vehicleInformationService;

    @Inject
    ObjectMapper objectMapper;

    @Incoming("vehicle_create")
    public void onVehicleCreateReceived(String message) {
        Future.<Void>future(promise -> {
            try {
                VehicleInformation vehicleInformation = deserializeMessage(message);
                vehicleInformationService.createVehicleInformation(vehicleInformation);
                promise.complete();
            } catch (Exception e) {
                log.log(Level.SEVERE, String.format("Error processing create vehicle information message: %s", message), e);
            }
        }).onComplete(res -> {
            if (res.failed()) {
                log.log(Level.SEVERE, String.format("Error processing create vehicle information message: %s", message), res.cause());
            }
        });
    }

    @Incoming("vehicle_update")
    public void onVehicleUpdateReceived(String message) {
        Future.<Void>future(promise -> {
            try {
                VehicleInformation vehicleInformation = deserializeMessage(message);
                vehicleInformationService.updateVehicleInformation(vehicleInformation);
                promise.complete();
            } catch (Exception e) {
                log.log(Level.SEVERE, String.format("Error processing update vehicle information message: %s", message), e);
            }
        }).onComplete(res -> {
            if (res.failed()) {
                log.log(Level.SEVERE, String.format("Error processing update vehicle information message: %s", message), res.cause());
            }
        });
    }

    private VehicleInformation deserializeMessage(String message) {
        try {
            return objectMapper.readValue(message, VehicleInformation.class);
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
    }
}
