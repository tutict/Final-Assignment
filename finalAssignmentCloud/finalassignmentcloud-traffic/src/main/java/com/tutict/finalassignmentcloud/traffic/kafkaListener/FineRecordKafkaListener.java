package com.tutict.finalassignmentcloud.traffic.kafkaListener;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentcloud.entity.FineRecord;
import com.tutict.finalassignmentcloud.traffic.service.FineRecordService;
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
public class FineRecordKafkaListener {

    private static final Logger log = Logger.getLogger(FineRecordKafkaListener.class.getName());

    private final FineRecordService fineRecordService;
    private final ObjectMapper objectMapper;

    @Autowired
    // 构造器注入依赖
    public FineRecordKafkaListener(FineRecordService fineRecordService,
                                   ObjectMapper objectMapper) {
        this.fineRecordService = fineRecordService;
        this.objectMapper = objectMapper;
    }

    // 监听 Kafka 消息（创建）
    @KafkaListener(topics = "fine_record_create", groupId = "fineRecordGroup", concurrency = "3")
    public void onFineRecordCreate(@Header(value = KafkaHeaders.RECEIVED_KEY, required = false) byte[] rawKey,
                                   @Payload String message) {
        log.log(Level.INFO, "Received Kafka message for FineRecord create: {0}", message);
        // 使用虚拟线程异步处理，避免阻塞监听线程
        Thread.ofVirtual().start(() -> processMessage(asKey(rawKey), message, "create"));
    }

    // 监听 Kafka 消息（更新）
    @KafkaListener(topics = "fine_record_update", groupId = "fineRecordGroup", concurrency = "3")
    public void onFineRecordUpdate(@Header(value = KafkaHeaders.RECEIVED_KEY, required = false) byte[] rawKey,
                                   @Payload String message) {
        log.log(Level.INFO, "Received Kafka message for FineRecord update: {0}", message);
        // 使用虚拟线程异步处理，避免阻塞监听线程
        Thread.ofVirtual().start(() -> processMessage(asKey(rawKey), message, "update"));
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

    // 反序列化消息体
    private FineRecord deserializeMessage(String message) {
        try {
            return objectMapper.readValue(message, FineRecord.class);
        } catch (Exception ex) {
            log.log(Level.SEVERE, "Failed to deserialize FineRecord message: {0}", message);
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

