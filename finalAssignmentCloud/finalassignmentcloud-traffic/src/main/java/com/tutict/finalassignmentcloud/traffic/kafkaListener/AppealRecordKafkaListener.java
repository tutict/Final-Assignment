package com.tutict.finalassignmentcloud.traffic.kafkaListener;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentcloud.entity.AppealRecord;
import com.tutict.finalassignmentcloud.traffic.service.AppealRecordService;
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
public class AppealRecordKafkaListener {

    private static final Logger log = Logger.getLogger(AppealRecordKafkaListener.class.getName());

    private final AppealRecordService appealRecordService;
    private final ObjectMapper objectMapper;

    @Autowired
    // 构造器注入依赖
    public AppealRecordKafkaListener(AppealRecordService appealRecordService,
                                     ObjectMapper objectMapper) {
        this.appealRecordService = appealRecordService;
        this.objectMapper = objectMapper;
    }

    // 监听 Kafka 消息（创建）
    @KafkaListener(topics = "appeal_record_create", groupId = "appealRecordGroup", concurrency = "3")
    public void onAppealRecordCreate(@Header(value = KafkaHeaders.RECEIVED_KEY, required = false) byte[] rawKey,
                                     @Payload String message) {
        log.log(Level.INFO, "Received Kafka message for AppealRecord create: {0}", message);
        // 使用虚拟线程异步处理，避免阻塞监听线程
        Thread.ofVirtual().start(() -> processMessage(asKey(rawKey), message, "create"));
    }

    // 监听 Kafka 消息（更新）
    @KafkaListener(topics = "appeal_record_update", groupId = "appealRecordGroup", concurrency = "3")
    public void onAppealRecordUpdate(@Header(value = KafkaHeaders.RECEIVED_KEY, required = false) byte[] rawKey,
                                     @Payload String message) {
        log.log(Level.INFO, "Received Kafka message for AppealRecord update: {0}", message);
        // 使用虚拟线程异步处理，避免阻塞监听线程
        Thread.ofVirtual().start(() -> processMessage(asKey(rawKey), message, "update"));
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

    // 反序列化消息体
    private AppealRecord deserializeMessage(String message) {
        try {
            return objectMapper.readValue(message, AppealRecord.class);
        } catch (Exception ex) {
            log.log(Level.SEVERE, "Failed to deserialize appeal record message: {0}", message);
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

