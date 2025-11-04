package com.tutict.finalassignmentbackend.kafkaListener;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentbackend.entity.FineRecord;
import com.tutict.finalassignmentbackend.mapper.FineRecordMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.kafka.annotation.EnableKafka;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Service;

import java.util.logging.Level;
import java.util.logging.Logger;

@Service
@EnableKafka
public class FineRecordKafkaListener {

    private static final Logger log = Logger.getLogger(FineRecordKafkaListener.class.getName());

    private final FineRecordMapper fineRecordMapper;
    private final ObjectMapper objectMapper;

    @Autowired
    public FineRecordKafkaListener(FineRecordMapper fineRecordMapper, ObjectMapper objectMapper) {
        this.fineRecordMapper = fineRecordMapper;
        this.objectMapper = objectMapper;
    }

    @KafkaListener(topics = "fine_record_create", groupId = "fineRecordGroup", concurrency = "3")
    public void onFineRecordCreateReceived(String message) {
        log.log(Level.INFO, "Received Kafka message for create: {0}", message);
        Thread.ofVirtual().start(() -> processMessage(message, "create"));
    }

    @KafkaListener(topics = "fine_record_update", groupId = "fineRecordGroup", concurrency = "3")
    public void onFineRecordUpdateReceived(String message) {
        log.log(Level.INFO, "Received Kafka message for update: {0}", message);
        Thread.ofVirtual().start(() -> processMessage(message, "update"));
    }

    private void processMessage(String message, String action) {
        try {
            FineRecord entity = deserializeMessage(message);
            if ("create".equals(action)) {
                entity.setFineId(null);
                fineRecordMapper.insert(entity);
            } else if ("update".equals(action)) {
                fineRecordMapper.updateById(entity);
            } else {
                log.log(Level.WARNING, "Unsupported action: {0}", action);
                return;
            }
            log.info(String.format("FineRecord %s action processed successfully: %s", action, entity));
        } catch (Exception e) {
            log.log(Level.SEVERE, String.format("Error processing %s FineRecord message: %s", action, message), e);
            throw new RuntimeException(String.format("Failed to process %s FineRecord message", action), e);
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
}
