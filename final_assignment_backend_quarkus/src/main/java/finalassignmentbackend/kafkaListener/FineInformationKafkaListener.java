package finalassignmentbackend.kafkaListener;

import com.fasterxml.jackson.databind.ObjectMapper;
import finalassignmentbackend.entity.FineInformation;
import finalassignmentbackend.service.FineInformationService;
import io.smallrye.common.annotation.RunOnVirtualThread;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.transaction.Transactional;
import org.eclipse.microprofile.reactive.messaging.Incoming;

import java.util.logging.Level;
import java.util.logging.Logger;

@ApplicationScoped
public class FineInformationKafkaListener {

    private static final Logger log = Logger.getLogger(FineInformationKafkaListener.class.getName());

    @Inject
    FineInformationService fineInformationService;

    @Inject
    ObjectMapper objectMapper;

    @Incoming("fine_create")
    @Transactional
    @RunOnVirtualThread
    public void onFineCreateReceived(String message) {
        processMessage(message, "create", fineInformationService::createFine);
    }

    @Incoming("fine_update")
    @Transactional
    @RunOnVirtualThread
    public void onFineUpdateReceived(String message) {
        processMessage(message, "update", fineInformationService::updateFine);
    }

    private void processMessage(String message, String action, MessageProcessor<FineInformation> processor) {
        try {
            FineInformation fineInformation = deserializeMessage(message);
            processor.process(fineInformation);
            log.info(String.format("Fine %s action processed successfully: %s", action, message));
        } catch (Exception e) {
            log.log(Level.SEVERE, String.format("Error processing %s fine message: %s", action, message), e);
            throw new RuntimeException(String.format("Failed to process %s fine message", action), e);
        }
    }

    private FineInformation deserializeMessage(String message) {
        try {
            return objectMapper.readValue(message, FineInformation.class);
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
