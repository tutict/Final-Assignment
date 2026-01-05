package com.tutict.finalassignmentbackend.kafkaListener;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentbackend.entity.DeductionRecord;
import com.tutict.finalassignmentbackend.service.DeductionRecordService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.kafka.support.KafkaHeaders;
import org.springframework.messaging.handler.annotation.Header;
import org.springframework.messaging.handler.annotation.Payload;
import org.springframework.stereotype.Service;

import java.util.logging.Level;
import java.util.logging.Logger;

@Service
// Kafka 监听器，处理消息
public class DeductionRecordKafkaListener {

    private static final Logger log = Logger.getLogger(DeductionRecordKafkaListener.class.getName());

    private final DeductionRecordService deductionRecordService;
    private final ObjectMapper objectMapper;

    // 构造器注入依赖
    @Autowired
    public DeductionRecordKafkaListener(DeductionRecordService deductionRecordService,
                                        ObjectMapper objectMapper) {
        this.deductionRecordService = deductionRecordService;
        this.objectMapper = objectMapper;
    }

    // 监听 Kafka 消息
    @KafkaListener(topics = "deduction_record_create", groupId = "deductionRecordGroup", concurrency = "3")
    public void onDeductionRecordCreate(@Header(value = KafkaHeaders.RECEIVED_KEY, required = false) byte[] rawKey,
                                        @Payload String message) {
        log.log(Level.INFO, "Received Kafka message for DeductionRecord create: {0}", message);
        // 使用虚拟线程异步处理，避免阻塞监听线程
        Thread.ofVirtual().start(() -> processMessage(asKey(rawKey), message, "create"));
    }

    // 监听 Kafka 消息
    @KafkaListener(topics = "deduction_record_update", groupId = "deductionRecordGroup", concurrency = "3")
    public void onDeductionRecordUpdate(@Header(value = KafkaHeaders.RECEIVED_KEY, required = false) byte[] rawKey,
                                        @Payload String message) {
        log.log(Level.INFO, "Received Kafka message for DeductionRecord update: {0}", message);
        // 使用虚拟线程异步处理，避免阻塞监听线程
        Thread.ofVirtual().start(() -> processMessage(asKey(rawKey), message, "update"));
    }

    // 统一处理消息并执行业务逻辑
    private void processMessage(String idempotencyKey, String message, String action) {
        if (isBlank(idempotencyKey)) {
            log.warning("Received DeductionRecord event without idempotency key, skipping");
            return;
        }
        DeductionRecord payload = deserializeMessage(message);
        if (payload == null) {
            log.warning("Received DeductionRecord event with empty payload, skipping");
            return;
        }
        try {
            if (deductionRecordService.shouldSkipProcessing(idempotencyKey)) {
                log.log(Level.INFO, "Skipping duplicate DeductionRecord event (key={0}, action={1})",
                        new Object[]{idempotencyKey, action});
                return;
            }

            DeductionRecord result;
            if ("create".equalsIgnoreCase(action)) {
                payload.setDeductionId(null);
                result = deductionRecordService.createDeductionRecord(payload);
            } else if ("update".equalsIgnoreCase(action)) {
                result = deductionRecordService.updateDeductionRecord(payload);
            } else {
                log.log(Level.WARNING, "Unsupported DeductionRecord action: {0}", action);
                return;
            }
            deductionRecordService.markHistorySuccess(idempotencyKey, result.getDeductionId());
        } catch (Exception ex) {
            deductionRecordService.markHistoryFailure(idempotencyKey, ex.getMessage());
            log.log(Level.SEVERE,
                    String.format("Error processing DeductionRecord event (key=%s, action=%s)", idempotencyKey, action),
                    ex);
            throw ex;
        }
    }

    // 反序列化消息体
    private DeductionRecord deserializeMessage(String message) {
        try {
            return objectMapper.readValue(message, DeductionRecord.class);
        } catch (Exception ex) {
            log.log(Level.SEVERE, "Failed to deserialize DeductionRecord message: {0}", message);
            return null;
        }
    }

    // 将 Kafka key 转为字符串
    private String asKey(byte[] rawKey) {
        return rawKey == null ? null : new String(rawKey);
    }

    // 判空
    private boolean isBlank(String value) {
        return value == null || value.trim().isEmpty();
    }
}
