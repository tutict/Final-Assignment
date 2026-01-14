package com.tutict.finalassignmentcloud.traffic.kafkaListener;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentcloud.entity.OffenseRecord;
import com.tutict.finalassignmentcloud.traffic.service.OffenseRecordService;
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
public class OffenseRecordKafkaListener {

    private static final Logger log = Logger.getLogger(OffenseRecordKafkaListener.class.getName());

    private final OffenseRecordService offenseRecordService;
    private final ObjectMapper objectMapper;

    @Autowired
    // 构造器注入依赖
    public OffenseRecordKafkaListener(OffenseRecordService offenseRecordService,
                                      ObjectMapper objectMapper) {
        this.offenseRecordService = offenseRecordService;
        this.objectMapper = objectMapper;
    }

    // 监听 Kafka 消息（创建）
    @KafkaListener(topics = "offense_record_create", groupId = "offenseRecordGroup", concurrency = "3")
    public void onOffenseRecordCreate(@Header(value = KafkaHeaders.RECEIVED_KEY, required = false) byte[] rawKey,
                                      @Payload String message) {
        log.log(Level.INFO, "Received Kafka message for OffenseRecord create: {0}", message);
        // 使用虚拟线程异步处理，避免阻塞监听线程
        Thread.ofVirtual().start(() -> processMessage(asKey(rawKey), message, "create"));
    }

    // 监听 Kafka 消息（更新）
    @KafkaListener(topics = "offense_record_update", groupId = "offenseRecordGroup", concurrency = "3")
    public void onOffenseRecordUpdate(@Header(value = KafkaHeaders.RECEIVED_KEY, required = false) byte[] rawKey,
                                      @Payload String message) {
        log.log(Level.INFO, "Received Kafka message for OffenseRecord update: {0}", message);
        // 使用虚拟线程异步处理，避免阻塞监听线程
        Thread.ofVirtual().start(() -> processMessage(asKey(rawKey), message, "update"));
    }

    // 统一处理消息并执行业务逻辑
    private void processMessage(String idempotencyKey, String message, String action) {
        if (isBlank(idempotencyKey)) {
            log.warning("Received OffenseRecord event without idempotency key, skipping");
            return;
        }
        OffenseRecord payload = deserializeMessage(message);
        if (payload == null) {
            log.warning("Received OffenseRecord event with empty payload, skipping");
            return;
        }
        try {
            if (offenseRecordService.shouldSkipProcessing(idempotencyKey)) {
                log.log(Level.INFO, "Skipping duplicate OffenseRecord event (key={0}, action={1})",
                        new Object[]{idempotencyKey, action});
                return;
            }

            OffenseRecord result;
            if ("create".equalsIgnoreCase(action)) {
                payload.setOffenseId(null);
                result = offenseRecordService.createOffenseRecord(payload);
            } else if ("update".equalsIgnoreCase(action)) {
                result = offenseRecordService.updateOffenseRecord(payload);
            } else {
                log.log(Level.WARNING, "Unsupported OffenseRecord action: {0}", action);
                return;
            }
            offenseRecordService.markHistorySuccess(idempotencyKey, result.getOffenseId());
        } catch (Exception ex) {
            offenseRecordService.markHistoryFailure(idempotencyKey, ex.getMessage());
            log.log(Level.SEVERE,
                    String.format("Error processing OffenseRecord event (key=%s, action=%s)", idempotencyKey, action),
                    ex);
            throw ex;
        }
    }

    // 反序列化消息体
    private OffenseRecord deserializeMessage(String message) {
        try {
            return objectMapper.readValue(message, OffenseRecord.class);
        } catch (Exception ex) {
            log.log(Level.SEVERE, "Failed to deserialize OffenseRecord message: {0}", message);
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

