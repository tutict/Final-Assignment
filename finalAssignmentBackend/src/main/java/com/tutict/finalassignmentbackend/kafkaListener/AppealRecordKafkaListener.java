package com.tutict.finalassignmentbackend.kafkaListener;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentbackend.entity.AppealRecord;
import com.tutict.finalassignmentbackend.service.AppealRecordService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.kafka.annotation.KafkaListener;
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
    private final ObjectMapper objectMapper;

    @Autowired
    public AppealRecordKafkaListener(AppealRecordService appealRecordService,
                                     ObjectMapper objectMapper) {
        this.appealRecordService = appealRecordService;
        this.objectMapper = objectMapper;
    }

    @KafkaListener(topics = "appeal_record_create", groupId = "appealRecordGroup", concurrency = "3")
    public void onAppealRecordCreate(@Header(value = KafkaHeaders.RECEIVED_KEY, required = false) byte[] rawKey,
                                     @Payload String message) {
        log.log(Level.INFO, "Received Kafka message for AppealRecord create: {0}", message);
        Thread.ofVirtual().start(() -> processMessage(asKey(rawKey), message, "create"));
    }

    @KafkaListener(topics = "appeal_record_update", groupId = "appealRecordGroup", concurrency = "3")
    public void onAppealRecordUpdate(@Header(value = KafkaHeaders.RECEIVED_KEY, required = false) byte[] rawKey,
                                     @Payload String message) {
        log.log(Level.INFO, "Received Kafka message for AppealRecord update: {0}", message);
        Thread.ofVirtual().start(() -> processMessage(asKey(rawKey), message, "update"));
    }

    private void processMessage(String idempotencyKey, String message, String action) {
        if (isBlank(idempotencyKey)) {
            log.warning("Received appeal record event without idempotency key, skipping");
            return;
        }
        AppealRecord payload = deserializeMessage(message);
        if (payload == null) {
            log.warning("Received appeal record event with empty payload, skipping");
            return;
        }
        try {
            if (appealRecordService.shouldSkipProcessing(idempotencyKey)) {
                log.log(Level.INFO, "Skipping duplicate appeal record event (key={0}, action={1})",
                        new Object[]{idempotencyKey, action});
                return;
            }

            AppealRecord result;
            if ("create".equalsIgnoreCase(action)) {
                payload.setAppealId(null);
                result = appealRecordService.createAppeal(payload);
            } else if ("update".equalsIgnoreCase(action)) {
                result = appealRecordService.updateAppeal(payload);
            } else {
                log.log(Level.WARNING, "Unsupported appeal record action: {0}", action);
                return;
            }
            appealRecordService.markHistorySuccess(idempotencyKey,
                    result.getAppealId() != null ? result.getAppealId() : null);
        } catch (Exception ex) {
            appealRecordService.markHistoryFailure(idempotencyKey, ex.getMessage());
            log.log(Level.SEVERE,
                    String.format("Error processing appeal record event (key=%s, action=%s)", idempotencyKey, action),
                    ex);
            throw ex;
        }
    }

    private AppealRecord deserializeMessage(String message) {
        try {
            return objectMapper.readValue(message, AppealRecord.class);
        } catch (Exception ex) {
            log.log(Level.SEVERE, "Failed to deserialize appeal record message: {0}", message);
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
