package com.tutict.finalassignmentbackend.kafkaListener;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentbackend.entity.AppealRecord;
import com.tutict.finalassignmentbackend.service.AppealRecordService;
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
// Kafka 监听器，处理消息
public class AppealRecordKafkaListener {

    private static final Logger log = Logger.getLogger(AppealRecordKafkaListener.class.getName());

    private final AppealRecordService appealRecordService;
    private final ObjectMapper objectMapper;

    // 构造器注入依赖
    @Autowired
    public AppealRecordKafkaListener(AppealRecordService appealRecordService,
                                     ObjectMapper objectMapper) {
        this.appealRecordService = appealRecordService;
        this.objectMapper = objectMapper;
    }

    // 监听 Kafka 消息
    @KafkaListener(topics = "${kafka.topics.appeal.create:appeal_record_create}", groupId = "${kafka.groups.appeal:appealRecordGroup}", concurrency = "3")
    public void onAppealRecordCreate(@Header(value = KafkaHeaders.RECEIVED_KEY, required = false) byte[] rawKey,
                                     @Payload String message,
                                      Acknowledgment ack) {
        log.log(Level.INFO, "Received Kafka message for AppealRecord create (payload omitted)");
        processMessage(asKey(rawKey), message, "create");
        ack.acknowledge();
    }

    // 监听 Kafka 消息
    @KafkaListener(topics = "${kafka.topics.appeal.update:appeal_record_update}", groupId = "${kafka.groups.appeal:appealRecordGroup}", concurrency = "3")
    public void onAppealRecordUpdate(@Header(value = KafkaHeaders.RECEIVED_KEY, required = false) byte[] rawKey,
                                     @Payload String message,
                                      Acknowledgment ack) {
        log.log(Level.INFO, "Received Kafka message for AppealRecord update (payload omitted)");
        processMessage(asKey(rawKey), message, "update");
        ack.acknowledge();
    }

    // 统一处理消息并执行业务逻辑
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
                result = appealRecordService.applyKafkaEvent(payload, action);
            } else if ("update".equalsIgnoreCase(action)) {
                result = appealRecordService.applyKafkaEvent(payload, action);
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
            log.log(Level.SEVERE, "Failed to deserialize Kafka message (payload omitted)", ex);
            throw new IllegalArgumentException("Failed to deserialize Kafka message", ex);
        }
    }
    private String asKey(byte[] rawKey) {
        return rawKey == null ? null : new String(rawKey);
    }

    // 判空
    private boolean isBlank(String value) {
        return value == null || value.trim().isEmpty();
    }
}
