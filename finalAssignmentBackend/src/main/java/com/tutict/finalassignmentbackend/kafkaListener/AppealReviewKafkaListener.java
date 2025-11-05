package com.tutict.finalassignmentbackend.kafkaListener;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentbackend.entity.AppealReview;
import com.tutict.finalassignmentbackend.service.AppealReviewService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.kafka.support.KafkaHeaders;
import org.springframework.messaging.handler.annotation.Header;
import org.springframework.messaging.handler.annotation.Payload;
import org.springframework.stereotype.Service;

import java.util.logging.Level;
import java.util.logging.Logger;

@Service
public class AppealReviewKafkaListener {

    private static final Logger log = Logger.getLogger(AppealReviewKafkaListener.class.getName());

    private final AppealReviewService appealReviewService;
    private final ObjectMapper objectMapper;

    @Autowired
    public AppealReviewKafkaListener(AppealReviewService appealReviewService,
                                     ObjectMapper objectMapper) {
        this.appealReviewService = appealReviewService;
        this.objectMapper = objectMapper;
    }

    @KafkaListener(topics = "appeal_review_create", groupId = "appealReviewGroup", concurrency = "3")
    public void onAppealReviewCreate(@Header(value = KafkaHeaders.RECEIVED_KEY, required = false) byte[] rawKey,
                                     @Payload String message) {
        log.log(Level.INFO, "Received Kafka message for AppealReview create: {0}", message);
        Thread.ofVirtual().start(() -> processMessage(asKey(rawKey), message, "create"));
    }

    @KafkaListener(topics = "appeal_review_update", groupId = "appealReviewGroup", concurrency = "3")
    public void onAppealReviewUpdate(@Header(value = KafkaHeaders.RECEIVED_KEY, required = false) byte[] rawKey,
                                     @Payload String message) {
        log.log(Level.INFO, "Received Kafka message for AppealReview update: {0}", message);
        Thread.ofVirtual().start(() -> processMessage(asKey(rawKey), message, "update"));
    }

    private void processMessage(String idempotencyKey, String message, String action) {
        if (isBlank(idempotencyKey)) {
            log.warning("Received appeal review event without idempotency key, skipping");
            return;
        }
        AppealReview payload = deserializeMessage(message);
        if (payload == null) {
            log.warning("Received appeal review event with empty payload, skipping");
            return;
        }
        try {
            if (appealReviewService.shouldSkipProcessing(idempotencyKey)) {
                log.log(Level.INFO, "Skipping duplicate appeal review event (key={0}, action={1})",
                        new Object[]{idempotencyKey, action});
                return;
            }
            AppealReview result;
            if ("create".equalsIgnoreCase(action)) {
                payload.setReviewId(null);
                result = appealReviewService.createReview(payload);
            } else if ("update".equalsIgnoreCase(action)) {
                result = appealReviewService.updateReview(payload);
            } else {
                log.log(Level.WARNING, "Unsupported appeal review action: {0}", action);
                return;
            }
            appealReviewService.markHistorySuccess(idempotencyKey,
                    result.getReviewId() != null ? result.getReviewId() : null);
        } catch (Exception ex) {
            appealReviewService.markHistoryFailure(idempotencyKey, ex.getMessage());
            log.log(Level.SEVERE,
                    String.format("Error processing appeal review event (key=%s, action=%s)", idempotencyKey, action),
                    ex);
            throw ex;
        }
    }

    private AppealReview deserializeMessage(String message) {
        try {
            return objectMapper.readValue(message, AppealReview.class);
        } catch (Exception ex) {
            log.log(Level.SEVERE, "Failed to deserialize appeal review message: {0}", message);
            return null;
        }
    }

    private String asKey(byte[] rawKey) {
        return rawKey == null ? null : new String(rawKey);
    }

    private boolean isBlank(String value) {
        return value == null || value.trim().isEmpty();
    }
}
