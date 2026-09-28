package finalassignmentbackend.kafkaListener;

import com.fasterxml.jackson.databind.ObjectMapper;
import finalassignmentbackend.entity.OffenseRecord;
import finalassignmentbackend.reliability.ConsumerAttempts;
import finalassignmentbackend.service.offense.OffenseRecordService;
import io.smallrye.common.annotation.RunOnVirtualThread;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
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
    @RunOnVirtualThread
    public void onOffenseCreateReceived(String message) {
        log.log(Level.INFO, "Received Kafka create message: {0}", message);
        OffenseRecord record = deserializeMessage(message);
        record.setOffenseId(null);
        ConsumerAttempts.run(() -> offenseRecordService.createOffenseRecord(record));
        log.info(String.format("Offense create processed: %s", record));
    }

    @Incoming("offense_update")
    @RunOnVirtualThread
    public void onOffenseUpdateReceived(String message) {
        log.log(Level.INFO, "Received Kafka update message: {0}", message);
        OffenseRecord record = deserializeMessage(message);
        ConsumerAttempts.run(() -> offenseRecordService.updateKafkaFullUpdate(record));
        log.info(String.format("Offense update processed: %s", record));
    }

    private OffenseRecord deserializeMessage(String message) {
        try {
            return objectMapper.readValue(message, OffenseRecord.class);
        } catch (Exception e) {
            log.log(Level.SEVERE, "Failed to deserialize message: {0}", message);
            throw new RuntimeException("Failed to deserialize message", e);
        }
    }


}
