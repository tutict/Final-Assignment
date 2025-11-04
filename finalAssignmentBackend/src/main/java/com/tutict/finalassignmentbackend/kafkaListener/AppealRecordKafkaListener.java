package com.tutict.finalassignmentbackend.kafkaListener;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentbackend.entity.AppealRecord;
import com.tutict.finalassignmentbackend.mapper.AppealRecordMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.kafka.annotation.EnableKafka;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Service;

import java.util.logging.Level;
import java.util.logging.Logger;

@Service
@EnableKafka
public class AppealRecordKafkaListener {

    private static final Logger log = Logger.getLogger(AppealRecordKafkaListener.class.getName());

    private final AppealRecordMapper appealRecordMapper;
    private final ObjectMapper objectMapper;

    @Autowired
    public AppealRecordKafkaListener(AppealRecordMapper appealRecordMapper, ObjectMapper objectMapper) {
        this.appealRecordMapper = appealRecordMapper;
        this.objectMapper = objectMapper;
    }

    @KafkaListener(topics = "appeal_record_create", groupId = "appealRecordGroup", concurrency = "3")
    public void onAppealRecordCreateReceived(String message) {
        log.log(Level.INFO, "Received Kafka message for create: {0}", message);
        Thread.ofVirtual().start(() -> processMessage(message, "create"));
    }

    @KafkaListener(topics = "appeal_record_update", groupId = "appealRecordGroup", concurrency = "3")
    public void onAppealRecordUpdateReceived(String message) {
        log.log(Level.INFO, "Received Kafka message for update: {0}", message);
        Thread.ofVirtual().start(() -> processMessage(message, "update"));
    }

    private void processMessage(String message, String action) {
        try {
            AppealRecord entity = deserializeMessage(message);
            if ("create".equals(action)) {
                entity.setAppealId(null);
                appealRecordMapper.insert(entity);
            } else if ("update".equals(action)) {
                appealRecordMapper.updateById(entity);
            } else {
                log.log(Level.WARNING, "Unsupported action: {0}", action);
                return;
            }
            log.info(String.format("AppealRecord %s action processed successfully: %s", action, entity));
        } catch (Exception e) {
            log.log(Level.SEVERE, String.format("Error processing %s AppealRecord message: %s", action, message), e);
            throw new RuntimeException(String.format("Failed to process %s AppealRecord message", action), e);
        }
    }

    private AppealRecord deserializeMessage(String message) {
        try {
            return objectMapper.readValue(message, AppealRecord.class);
        } catch (Exception e) {
            log.log(Level.SEVERE, "Failed to deserialize message: {0}", message);
            throw new RuntimeException("Failed to deserialize message", e);
        }
    }
}
