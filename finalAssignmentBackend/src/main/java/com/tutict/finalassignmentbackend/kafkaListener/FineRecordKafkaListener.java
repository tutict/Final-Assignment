package com.tutict.finalassignmentbackend.kafkaListener;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentbackend.entity.FineRecord;
import com.tutict.finalassignmentbackend.service.FineRecordService;
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
public class FineRecordKafkaListener {

    private static final Logger log = Logger.getLogger(FineRecordKafkaListener.class.getName());

    private final FineRecordService fineRecordService;
    private final ObjectMapper objectMapper;

    // 构造器注入依赖
    @Autowired
    public FineRecordKafkaListener(FineRecordService fineRecordService,
                                   ObjectMapper objectMapper) {
        this.fineRecordService = fineRecordService;
        this.objectMapper = objectMapper;
    }

    // 监听 Kafka 消息
    @KafkaListener(topics = "${kafka.topics.fine.create:fine_record_create}", groupId = "${kafka.groups.fine:fineRecordGroup}", concurrency = "3")
    public void onFineRecordCreate(@Header(value = KafkaHeaders.RECEIVED_KEY, required = false) byte[] rawKey,
                                   @Payload String message,
                                      Acknowledgment ack) {
        log.log(Level.INFO, "Received Kafka message for FineRecord create (payload omitted)");
        processMessage(asKey(rawKey), message, "create");
        ack.acknowledge();
    }

    // 监听 Kafka 消息
    @KafkaListener(topics = "${kafka.topics.fine.update:fine_record_update}", groupId = "${kafka.groups.fine:fineRecordGroup}", concurrency = "3")
    public void onFineRecordUpdate(@Header(value = KafkaHeaders.RECEIVED_KEY, required = false) byte[] rawKey,
                                   @Payload String message,
                                      Acknowledgment ack) {
        log.log(Level.INFO, "Received Kafka message for FineRecord update (payload omitted)");
        processMessage(asKey(rawKey), message, "update");
        ack.acknowledge();
    }

    // 统一处理消息并执行业务逻辑
    private void processMessage(String idempotencyKey, String message, String action) {
        if (isBlank(idempotencyKey)) {
            log.warning("Received FineRecord event without idempotency key, skipping");
            return;
        }
        FineRecord payload = deserializeMessage(message);
        if (payload == null) {
            log.warning("Received FineRecord event with empty payload, skipping");
            return;
        }

        try {
            if (fineRecordService.shouldSkipProcessing(idempotencyKey)) {
                log.log(Level.INFO, "Skipping duplicate FineRecord event (key={0}, action={1})",
                        new Object[]{idempotencyKey, action});
                return;
            }

            FineRecord result;
            if ("create".equalsIgnoreCase(action)) {
                payload.setFineId(null);
                result = fineRecordService.createFineRecord(payload);
            } else if ("update".equalsIgnoreCase(action)) {
                result = fineRecordService.updateFineRecord(payload);
            } else {
                log.log(Level.WARNING, "Unsupported FineRecord action: {0}", action);
                return;
            }
            fineRecordService.markHistorySuccess(idempotencyKey, result.getFineId());
        } catch (Exception ex) {
            fineRecordService.markHistoryFailure(idempotencyKey, ex.getMessage());
            log.log(Level.SEVERE,
                    String.format("Error processing FineRecord event (key=%s, action=%s)", idempotencyKey, action),
                    ex);
            throw ex;
        }
    }
    private FineRecord deserializeMessage(String message) {
        try {
            return objectMapper.readValue(message, FineRecord.class);
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
