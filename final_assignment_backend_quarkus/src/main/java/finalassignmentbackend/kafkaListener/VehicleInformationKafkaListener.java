package finalassignmentbackend.kafkaListener;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.oracle.svm.core.annotate.Inject;
import finalassignmentbackend.entity.VehicleInformation;
import finalassignmentbackend.service.VehicleInformationService;
import io.vertx.core.Future;
import jakarta.enterprise.context.ApplicationScoped;
import org.eclipse.microprofile.reactive.messaging.Incoming;
import org.jboss.logging.Logger;

@ApplicationScoped
public class VehicleInformationKafkaListener {

    private static final Logger log = Logger.getLogger(VehicleInformationKafkaListener.class);

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
                log.errorf("Error processing create vehicle information message: %s", message, e);
                promise.fail(e);
            }
        }).onComplete(res -> {
            if (res.failed()) {
                log.errorf("Error processing create vehicle information message: %s", message, res.cause());
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
                log.errorf("Error processing update vehicle information message: %s", message, e);
                promise.fail(e);
            }
        }).onComplete(res -> {
            if (res.failed()) {
                log.errorf("Error processing update vehicle information message: %s", message, res.cause());
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
