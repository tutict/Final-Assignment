package com.tutict.finalassignmentbackend.kafkaListener;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentbackend.entity.OffenseRecord;
import com.tutict.finalassignmentbackend.mapper.OffenseRecordMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.kafka.annotation.EnableKafka;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Service;

import java.util.logging.Level;
import java.util.logging.Logger;

@Service
@EnableKafka
public class OffenseRecordKafkaListener {

    private static final Logger log = Logger.getLogger(OffenseRecordKafkaListener.class.getName());

    private final OffenseRecordMapper offenseRecordMapper;
    private final ObjectMapper objectMapper;

    @Autowired
    public OffenseRecordKafkaListener(OffenseRecordMapper offenseRecordMapper, ObjectMapper objectMapper) {
        this.offenseRecordMapper = offenseRecordMapper;
        this.objectMapper = objectMapper;
    }

    @KafkaListener(topics = "offense_record_create", groupId = "offenseRecordGroup", concurrency = "3")
    public void onOffenseRecordCreateReceived(String message) {
        log.log(Level.INFO, "Received Kafka message for create: {0}", message);
        Thread.ofVirtual().start(() -> processMessage(message, "create"));
    }

    @KafkaListener(topics = "offense_record_update", groupId = "offenseRecordGroup", concurrency = "3")
    public void onOffenseRecordUpdateReceived(String message) {
        log.log(Level.INFO, "Received Kafka message for update: {0}", message);
        Thread.ofVirtual().start(() -> processMessage(message, "update"));
    }

    private void processMessage(String message, String action) {
        try {
            OffenseRecord entity = deserializeMessage(message);
            if ("create".equals(action)) {
                entity.setOffenseId(null);
                offenseRecordMapper.insert(entity);
            } else if ("update".equals(action)) {
                offenseRecordMapper.updateById(entity);
            } else {
                log.log(Level.WARNING, "Unsupported action: {0}", action);
                return;
            }
            log.info(String.format("OffenseRecord %s action processed successfully: %s", action, entity));
        } catch (Exception e) {
            log.log(Level.SEVERE, String.format("Error processing %s OffenseRecord message: %s", action, message), e);
            throw new RuntimeException(String.format("Failed to process %s OffenseRecord message", action), e);
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
}
