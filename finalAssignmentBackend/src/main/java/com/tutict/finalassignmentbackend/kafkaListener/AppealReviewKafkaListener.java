package com.tutict.finalassignmentbackend.kafkaListener;

import com.tutict.finalassignmentbackend.common.idempotency.IdempotentKafkaMessageProcessor;
import com.tutict.finalassignmentbackend.entity.appeal.AppealReview;
import com.tutict.finalassignmentbackend.service.appeal.AppealReviewService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.kafka.support.Acknowledgment;
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
    private final IdempotentKafkaMessageProcessor messageProcessor;

    @Autowired
    public AppealReviewKafkaListener(AppealReviewService appealReviewService,
                                     IdempotentKafkaMessageProcessor messageProcessor) {
        this.appealReviewService = appealReviewService;
        this.messageProcessor = messageProcessor;
    }

    @KafkaListener(topics = "${kafka.topics.appeal-review.create:appeal_review_create}", groupId = "${kafka.groups.appeal-review:appealReviewGroup}", concurrency = "3")
    public void onAppealReviewCreate(@Header(value = KafkaHeaders.RECEIVED_KEY, required = false) byte[] rawKey,
                                     @Payload String message,
                                     Acknowledgment ack) {
        log.log(Level.INFO, "Received Kafka message for AppealReview create (payload omitted)");
        processMessage(asKey(rawKey), message, "create", ack);
    }

    @KafkaListener(topics = "${kafka.topics.appeal-review.update:appeal_review_update}", groupId = "${kafka.groups.appeal-review:appealReviewGroup}", concurrency = "3")
    public void onAppealReviewUpdate(@Header(value = KafkaHeaders.RECEIVED_KEY, required = false) byte[] rawKey,
                                     @Payload String message,
                                     Acknowledgment ack) {
        log.log(Level.INFO, "Received Kafka message for AppealReview update (payload omitted)");
        processMessage(asKey(rawKey), message, "update", ack);
    }

    private void processMessage(String idempotencyKey, String message, String action, Acknowledgment ack) {
        if (isBlank(idempotencyKey)) {
            log.warning("Received appeal review event without idempotency key, skipping");
            acknowledge(ack);
            return;
        }
        messageProcessor.process(
                idempotencyKey,
                message,
                ack,
                "AppealReview",
                action,
                appealReviewService::shouldSkipProcessing,
                payload -> processPayload(payload, action),
                (key, result) -> {
                    if (result != null && result.getReviewId() != null) {
                        appealReviewService.markHistorySuccess(key, result.getReviewId());
                    }
                },
                (key, ex) -> appealReviewService.markHistoryFailure(key, ex.getMessage())
        );
    }

    private AppealReview processPayload(String message, String action) {
        AppealReview payload = messageProcessor.deserialize(message, AppealReview.class);
        if ("create".equalsIgnoreCase(action)) {
            payload.setReviewId(null);
            return appealReviewService.createReview(payload);
        }
        if ("update".equalsIgnoreCase(action)) {
            return appealReviewService.updateReview(payload);
        }
        log.log(Level.WARNING, "Unsupported appeal review action: {0}", action);
        return null;
    }

    private String asKey(byte[] rawKey) {
        return rawKey == null ? null : new String(rawKey);
    }

    private boolean isBlank(String value) {
        return value == null || value.trim().isEmpty();
    }

    private void acknowledge(Acknowledgment acknowledgment) {
        if (acknowledgment != null) {
            acknowledgment.acknowledge();
        }
    }
}
