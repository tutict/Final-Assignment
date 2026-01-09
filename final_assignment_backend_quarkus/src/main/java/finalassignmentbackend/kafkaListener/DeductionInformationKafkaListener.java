package finalassignmentbackend.kafkaListener;

import com.fasterxml.jackson.databind.ObjectMapper;
import finalassignmentbackend.entity.DeductionRecord;
import finalassignmentbackend.service.DeductionRecordService;
import io.smallrye.common.annotation.RunOnVirtualThread;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.transaction.Transactional;
import org.eclipse.microprofile.reactive.messaging.Incoming;

import java.util.logging.Level;
import java.util.logging.Logger;

// Kafka listener for deduction record messages (new schema)
@ApplicationScoped
public class DeductionInformationKafkaListener {

    private static final Logger log = Logger.getLogger(DeductionInformationKafkaListener.class.getName());

    @Inject
    DeductionRecordService deductionRecordService;

    @Inject
    ObjectMapper objectMapper;

    @Incoming("deduction_create")
    @Transactional
    @RunOnVirtualThread
    public void onDeductionCreateReceived(String message) {
        log.log(Level.INFO, "Received Kafka create message: {0}", message);
        processMessage(message, "create", deductionRecordService::createDeductionRecord);
    }

    @Incoming("deduction_update")
    @Transactional
    @RunOnVirtualThread
    public void onDeductionUpdateReceived(String message) {
        log.log(Level.INFO, "Received Kafka update message: {0}", message);
        processMessage(message, "update", deductionRecordService::updateDeductionRecord);
    }

    private void processMessage(String message, String action, MessageProcessor<DeductionRecord> processor) {
        try {
            DeductionRecord record = deserializeMessage(message);
            if ("create".equals(action)) {
                record.setDeductionId(null);
            }
            processor.process(record);
            log.info(String.format("Deduction %s processed: %s", action, record));
        } catch (Exception e) {
            log.log(Level.SEVERE, String.format("Failed to process deduction %s message: %s", action, message), e);
            throw new RuntimeException(String.format("Failed to process deduction %s message", action), e);
        }
    }

    private DeductionRecord deserializeMessage(String message) {
        try {
            return objectMapper.readValue(message, DeductionRecord.class);
        } catch (Exception e) {
            log.log(Level.SEVERE, "Failed to deserialize message: {0}", message);
            throw new RuntimeException("Failed to deserialize message", e);
        }
    }

    @FunctionalInterface
    private interface MessageProcessor<T> {
        void process(T t) throws Exception;
    }
}
