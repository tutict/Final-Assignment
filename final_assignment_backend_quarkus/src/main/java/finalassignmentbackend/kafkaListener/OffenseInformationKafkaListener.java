package finalassignmentbackend.kafkaListener;

import com.fasterxml.jackson.databind.ObjectMapper;
import finalassignmentbackend.entity.OffenseRecord;
import finalassignmentbackend.service.OffenseRecordService;
import io.smallrye.common.annotation.RunOnVirtualThread;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.transaction.Transactional;
import org.eclipse.microprofile.reactive.messaging.Incoming;

import java.util.logging.Level;
import java.util.logging.Logger;

// Kafka listener for offense record messages (new schema)
@ApplicationScoped
public class OffenseInformationKafkaListener {

    private static final Logger log = Logger.getLogger(OffenseInformationKafkaListener.class.getName());

    @Inject
    OffenseRecordService offenseRecordService;

    @Inject
    ObjectMapper objectMapper;

    @Incoming("offense_create")
    @Transactional
    @RunOnVirtualThread
    public void onOffenseCreateReceived(String message) {
        log.log(Level.INFO, "Received Kafka create message: {0}", message);
        processMessage(message, "create", offenseRecordService::createOffenseRecord);
    }

    @Incoming("offense_update")
    @Transactional
    @RunOnVirtualThread
    public void onOffenseUpdateReceived(String message) {
        log.log(Level.INFO, "Received Kafka update message: {0}", message);
        processMessage(message, "update", offenseRecordService::updateOffenseRecord);
    }

    private void processMessage(String message, String action, MessageProcessor<OffenseRecord> processor) {
        try {
            OffenseRecord record = deserializeMessage(message);
            if ("create".equals(action)) {
                record.setOffenseId(null);
            }
            processor.process(record);
            log.info(String.format("Offense %s processed: %s", action, record));
        } catch (Exception e) {
            log.log(Level.SEVERE, String.format("Failed to process offense %s message: %s", action, message), e);
            throw new RuntimeException(String.format("Failed to process offense %s message", action), e);
        }
    }

    private OffenseRecord deserializeMessage(String message) {
        try {
            return objectMapper.readValue(message, OffenseRecord.class);
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
