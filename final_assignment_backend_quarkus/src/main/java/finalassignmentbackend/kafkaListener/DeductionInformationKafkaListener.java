package finalassignmentbackend.kafkaListener;

import com.fasterxml.jackson.databind.ObjectMapper;
import finalassignmentbackend.entity.DeductionInformation;
import finalassignmentbackend.service.DeductionInformationService;
import io.smallrye.common.annotation.RunOnVirtualThread;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.transaction.Transactional;
import org.eclipse.microprofile.reactive.messaging.Incoming;

import java.util.logging.Level;
import java.util.logging.Logger;

@ApplicationScoped
public class DeductionInformationKafkaListener {

    private static final Logger log = Logger.getLogger(DeductionInformationKafkaListener.class.getName());

    @Inject
    DeductionInformationService deductionInformationService;

    @Inject
    ObjectMapper objectMapper;

    @Incoming("deduction_create")
    @Transactional
    @RunOnVirtualThread
    public void onDeductionCreateReceived(String message) {
        processMessage(message, "create", deductionInformationService::createDeduction);
    }

    @Incoming("deduction_update")
    @Transactional
    @RunOnVirtualThread
    public void onDeductionUpdateReceived(String message) {
        processMessage(message, "update", deductionInformationService::updateDeduction);
    }

    private void processMessage(String message, String action, MessageProcessor<DeductionInformation> processor) {
        try {
            DeductionInformation deductionInformation = deserializeMessage(message);
            processor.process(deductionInformation);
            log.info(String.format("Deduction %s action processed successfully: %s", action, message));
        } catch (Exception e) {
            log.log(Level.SEVERE, String.format("Error processing %s deduction message: %s", action, message), e);
            throw new RuntimeException(String.format("Failed to process %s deduction message", action), e);
        }
    }

    private DeductionInformation deserializeMessage(String message) {
        try {
            return objectMapper.readValue(message, DeductionInformation.class);
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
