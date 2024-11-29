package finalassignmentbackend.kafkaListener;

import com.fasterxml.jackson.databind.ObjectMapper;
import finalassignmentbackend.entity.FineInformation;
import finalassignmentbackend.service.FineInformationService;
import io.vertx.core.Future;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import org.eclipse.microprofile.reactive.messaging.Incoming;

import java.util.logging.Level;
import java.util.logging.Logger;

@ApplicationScoped
public class FineInformationKafkaListener {

    private static final Logger log = Logger.getLogger(String.valueOf(FineInformationKafkaListener.class));

    @Inject
    FineInformationService fineInformationService;

    @Inject
    ObjectMapper objectMapper;

    @Incoming("fine_create")
    public void onFineCreateReceived(String message) {
        Future.<Void>future(promise -> {
            try {
                FineInformation fineInformation = deserializeMessage(message);
                fineInformationService.createFine(fineInformation);
                promise.complete();
            } catch (Exception e) {
                log.log(Level.SEVERE, String.format("Error processing create fine message: %s", message), e);
            }
        }).onComplete(res -> {
            if (res.failed()) {
                log.log(Level.SEVERE, String.format("Error processing create fine message: %s", message), res.cause());
            }
        });
    }

    @Incoming("fine_update")
    public void onFineUpdateReceived(String message) {
        Future.<Void>future(promise -> {
            try {
                FineInformation fineInformation = deserializeMessage(message);
                fineInformationService.updateFine(fineInformation);
                promise.complete();
            } catch (Exception e) {
                log.log(Level.SEVERE, String.format("Error processing update fine message: %s", message), e);
            }
        }).onComplete(res -> {
            if (res.failed()) {
                log.log(Level.SEVERE, String.format("Error processing update fine message: %s", message), res.cause());
            }
        });
    }

    private FineInformation deserializeMessage(String message) {
        try {
            return objectMapper.readValue(message, FineInformation.class);
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
    }
}
