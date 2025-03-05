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

// 声明一个Kafka监听器组件，用于处理申诉管理相关的消息
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
        Thread.ofVirtual().start(() -> processMessage(message, "create", appealManagementService::createAppeal));
    }

    @KafkaListener(topics = "appeal_updated", groupId = "appealGroup", concurrency = "3")
    public void onAppealUpdateReceived(String message) {
        Thread.ofVirtual().start(() -> processMessage(message, "update", appealManagementService::updateAppeal));
    }

    private void processMessage(String message, String action, MessageProcessor<AppealManagement> processor) {
        try {
            AppealManagement appealManagement = deserializeMessage(message);
            if ("create".equals(action)) {
                appealManagement.setAppealId(null);
            }
            processor.process(appealManagement);
            log.info(String.format("Appeal %s action processed successfully: %s", action, message));
        } catch (Exception e) {
            log.log(Level.SEVERE, String.format("Error processing %s appeal message: %s", action, message), e);
            throw new RuntimeException(String.format("Failed to process %s appeal message", action), e);
        }
    }
    private AppealManagement deserializeMessage(String message) {
        try {
            return objectMapper.readValue(message, AppealManagement.class);
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