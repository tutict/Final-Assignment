package com.tutict.finalassignmentbackend.kafkaListener;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentbackend.entity.AppealReview;
import com.tutict.finalassignmentbackend.mapper.AppealReviewMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.kafka.annotation.EnableKafka;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Service;

import java.util.logging.Level;
import java.util.logging.Logger;

@Service
@EnableKafka
public class AppealReviewKafkaListener {

    private static final Logger log = Logger.getLogger(AppealReviewKafkaListener.class.getName());

    private final AppealReviewMapper appealReviewMapper;
    private final ObjectMapper objectMapper;

    @Autowired
    public AppealReviewKafkaListener(AppealReviewMapper appealReviewMapper, ObjectMapper objectMapper) {
        this.appealReviewMapper = appealReviewMapper;
        this.objectMapper = objectMapper;
    }

    @KafkaListener(topics = "appeal_review_create", groupId = "appealReviewGroup", concurrency = "3")
    public void onAppealReviewCreateReceived(String message) {
        log.log(Level.INFO, "Received Kafka message for create: {0}", message);
        Thread.ofVirtual().start(() -> processMessage(message, "create"));
    }

    @KafkaListener(topics = "appeal_review_update", groupId = "appealReviewGroup", concurrency = "3")
    public void onAppealReviewUpdateReceived(String message) {
        log.log(Level.INFO, "Received Kafka message for update: {0}", message);
        Thread.ofVirtual().start(() -> processMessage(message, "update"));
    }

    private void processMessage(String message, String action) {
        try {
            AppealReview entity = deserializeMessage(message);
            if ("create".equals(action)) {
                entity.setReviewId(null);
                appealReviewMapper.insert(entity);
            } else if ("update".equals(action)) {
                appealReviewMapper.updateById(entity);
            } else {
                log.log(Level.WARNING, "Unsupported action: {0}", action);
                return;
            }
            log.info(String.format("AppealReview %s action processed successfully: %s", action, entity));
        } catch (Exception e) {
            log.log(Level.SEVERE, String.format("Error processing %s AppealReview message: %s", action, message), e);
            throw new RuntimeException(String.format("Failed to process %s AppealReview message", action), e);
        }
    }

    private AppealReview deserializeMessage(String message) {
        try {
            return objectMapper.readValue(message, AppealReview.class);
        } catch (Exception e) {
            log.log(Level.SEVERE, "Failed to deserialize message: {0}", message);
            throw new RuntimeException("Failed to deserialize message", e);
        }
    }
}
