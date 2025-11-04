package com.tutict.finalassignmentbackend.kafkaListener;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentbackend.entity.DeductionRecord;
import com.tutict.finalassignmentbackend.mapper.DeductionRecordMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.kafka.annotation.EnableKafka;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Service;

import java.util.logging.Level;
import java.util.logging.Logger;

@Service
@EnableKafka
public class DeductionRecordKafkaListener {

    private static final Logger log = Logger.getLogger(DeductionRecordKafkaListener.class.getName());

    private final DeductionRecordMapper deductionRecordMapper;
    private final ObjectMapper objectMapper;

    @Autowired
    public DeductionRecordKafkaListener(DeductionRecordMapper deductionRecordMapper, ObjectMapper objectMapper) {
        this.deductionRecordMapper = deductionRecordMapper;
        this.objectMapper = objectMapper;
    }

    @KafkaListener(topics = "deduction_record_create", groupId = "deductionRecordGroup", concurrency = "3")
    public void onDeductionRecordCreateReceived(String message) {
        log.log(Level.INFO, "Received Kafka message for create: {0}", message);
        Thread.ofVirtual().start(() -> processMessage(message, "create"));
    }

    @KafkaListener(topics = "deduction_record_update", groupId = "deductionRecordGroup", concurrency = "3")
    public void onDeductionRecordUpdateReceived(String message) {
        log.log(Level.INFO, "Received Kafka message for update: {0}", message);
        Thread.ofVirtual().start(() -> processMessage(message, "update"));
    }

    private void processMessage(String message, String action) {
        try {
            DeductionRecord entity = deserializeMessage(message);
            if ("create".equals(action)) {
                entity.setDeductionId(null);
                deductionRecordMapper.insert(entity);
            } else if ("update".equals(action)) {
                deductionRecordMapper.updateById(entity);
            } else {
                log.log(Level.WARNING, "Unsupported action: {0}", action);
                return;
            }
            log.info(String.format("DeductionRecord %s action processed successfully: %s", action, entity));
        } catch (Exception e) {
            log.log(Level.SEVERE, String.format("Error processing %s DeductionRecord message: %s", action, message), e);
            throw new RuntimeException(String.format("Failed to process %s DeductionRecord message", action), e);
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
}
