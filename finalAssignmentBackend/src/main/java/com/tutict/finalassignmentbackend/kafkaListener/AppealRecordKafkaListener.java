package com.tutict.finalassignmentbackend.kafkaListener;

import com.tutict.finalassignmentbackend.common.idempotency.IdempotentKafkaMessageProcessor;
import com.tutict.finalassignmentbackend.entity.appeal.AppealRecord;
import com.tutict.finalassignmentbackend.service.appeal.AppealRecordService;
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
public class AppealRecordKafkaListener {

    private static final Logger log = Logger.getLogger(AppealRecordKafkaListener.class.getName());

    private final AppealRecordService appealRecordService;
    private final IdempotentKafkaMessageProcessor messageProcessor;

    @Autowired
    public AppealRecordKafkaListener(AppealRecordService appealRecordService,
                                     IdempotentKafkaMessageProcessor messageProcessor) {
        this.appealRecordService = appealRecordService;
        this.messageProcessor = messageProcessor;
    }

    @KafkaListener(topics = "${kafka.topics.appeal.create:appeal_record_create}", groupId = "${kafka.groups.appeal:appealRecordGroup}", concurrency = "3")
    public void onAppealRecordCreate(@Header(value = KafkaHeaders.RECEIVED_KEY, required = false) byte[] rawKey,
                                     @Payload String message,
                                     Acknowledgment ack) {
        log.log(Level.INFO, "Received Kafka message for AppealRecord create (payload omitted)");
        processMessage(asKey(rawKey), message, "create", ack);
    }

    @KafkaListener(topics = "${kafka.topics.appeal.update:appeal_record_update}", groupId = "${kafka.groups.appeal:appealRecordGroup}", concurrency = "3")
    public void onAppealRecordUpdate(@Header(value = KafkaHeaders.RECEIVED_KEY, required = false) byte[] rawKey,
                                     @Payload String message,
                                     Acknowledgment ack) {
        log.log(Level.INFO, "Received Kafka message for AppealRecord update (payload omitted)");
        processMessage(asKey(rawKey), message, "update", ack);
    }

    private void processMessage(String idempotencyKey, String message, String action, Acknowledgment ack) {
        if (isBlank(idempotencyKey)) {
            log.warning("Received appeal record event without idempotency key, skipping");
            acknowledge(ack);
            return;
        }
        messageProcessor.process(
                idempotencyKey,
                message,
                ack,
                "AppealRecord",
                action,
                appealRecordService::shouldSkipProcessing,
                payload -> processPayload(payload, action),
                (key, result) -> {
                    if (result != null && result.getAppealId() != null) {
                        appealRecordService.markHistorySuccess(key, result.getAppealId());
                    }
                },
                (key, ex) -> appealRecordService.markHistoryFailure(key, ex.getMessage())
        );
    }

    private AppealRecord processPayload(String message, String action) {
        AppealRecord payload = messageProcessor.deserialize(message, AppealRecord.class);
        if ("create".equalsIgnoreCase(action)) {
            payload.setAppealId(null);
            return appealRecordService.applyKafkaEvent(payload, action);
        }
        if ("update".equalsIgnoreCase(action)) {
            return appealRecordService.applyKafkaEvent(payload, action);
        }
        log.log(Level.WARNING, "Unsupported appeal record action: {0}", action);
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
