package com.tutict.finalassignmentbackend.kafkaListener;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentbackend.entity.AppealManagement;
import com.tutict.finalassignmentbackend.service.AppealManagementService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.kafka.annotation.EnableKafka;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Service;

import java.util.logging.Level;
import java.util.logging.Logger;

@Service
@EnableKafka
public class AppealManagementKafkaListener {

    private static final Logger log = Logger.getLogger(AppealManagementKafkaListener.class.getName());

    private final AppealManagementService appealManagementService;
    private final ObjectMapper objectMapper;

    @Autowired
    public AppealManagementKafkaListener(AppealManagementService appealManagementService, ObjectMapper objectMapper) {
        this.appealManagementService = appealManagementService;
        this.objectMapper = objectMapper;
    }

    @KafkaListener(topics = "appeal_create", groupId = "appealGroup", concurrency = "3")
    public void onAppealCreateReceived(String message) {
        log.log(Level.INFO, "Received Kafka message for create: {0}", message);
        Thread.ofVirtual().start(() -> processMessage(message, "create", appealManagementService::createAppeal));
    }

    @KafkaListener(topics = "appeal_updated", groupId = "appealGroup", concurrency = "3")
    public void onAppealUpdateReceived(String message) {
        log.log(Level.INFO, "Received Kafka message for update: {0}", message);
        Thread.ofVirtual().start(() -> processMessage(message, "update", appealManagementService::updateAppeal));
    }

    private void processMessage(String message, String action, MessageProcessor<AppealManagement> processor) {
        try {
            AppealManagement appealManagement = deserializeMessage(message);
            log.log(Level.INFO, "Deserialized appeal: {0}", appealManagement);
            if ("create".equals(action)) {
                appealManagement.setAppealId(null);
            }
            processor.process(appealManagement);
            log.info(String.format("Appeal %s action processed successfully: %s", action, appealManagement));
        } catch (Exception e) {
            log.log(Level.SEVERE, String.format("Error processing %s appeal message: %s", action, message), e);
            throw new RuntimeException(String.format("Failed to process %s appeal message", action), e);
        }
    }

    private AppealManagement deserializeMessage(String message) {
        try {
            AppealManagement appeal = objectMapper.readValue(message, AppealManagement.class);
            if (appeal.getAppellantName() == null || appeal.getAppellantName().trim().isEmpty()) {
                log.log(Level.SEVERE, "Deserialized appeal has null/empty appellantName: {0}", message);
                throw new IllegalArgumentException("Appellant name cannot be null or empty in Kafka message");
            }
            return appeal;
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