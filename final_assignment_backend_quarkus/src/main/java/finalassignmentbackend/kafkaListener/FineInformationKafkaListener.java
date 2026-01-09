package finalassignmentbackend.kafkaListener;

import com.fasterxml.jackson.databind.ObjectMapper;
import finalassignmentbackend.entity.FineRecord;
import finalassignmentbackend.service.FineRecordService;
import io.smallrye.common.annotation.RunOnVirtualThread;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.transaction.Transactional;
import org.eclipse.microprofile.reactive.messaging.Incoming;

import java.util.logging.Level;
import java.util.logging.Logger;

// Kafka listener for fine record messages (new schema)
@ApplicationScoped
public class FineInformationKafkaListener {

    private static final Logger log = Logger.getLogger(FineInformationKafkaListener.class.getName());

    @Inject
    FineRecordService fineRecordService;

    @Inject
    ObjectMapper objectMapper;

    @Incoming("fine_create")
    @Transactional
    @RunOnVirtualThread
    public void onFineCreateReceived(String message) {
        log.log(Level.INFO, "Received Kafka create message: {0}", message);
        processMessage(message, "create", fineRecordService::createFineRecord);
    }

    @Incoming("fine_update")
    @Transactional
    @RunOnVirtualThread
    public void onFineUpdateReceived(String message) {
        log.log(Level.INFO, "Received Kafka update message: {0}", message);
        processMessage(message, "update", fineRecordService::updateFineRecord);
    }

    private void processMessage(String message, String action, MessageProcessor<FineRecord> processor) {
        try {
            FineRecord record = deserializeMessage(message);
            if ("create".equals(action)) {
                record.setFineId(null);
            }
            processor.process(record);
            log.info(String.format("Fine %s processed: %s", action, record));
        } catch (Exception e) {
            log.log(Level.SEVERE, String.format("Failed to process fine %s message: %s", action, message), e);
            throw new RuntimeException(String.format("Failed to process fine %s message", action), e);
        }
    }

    private FineRecord deserializeMessage(String message) {
        try {
            return objectMapper.readValue(message, FineRecord.class);
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
