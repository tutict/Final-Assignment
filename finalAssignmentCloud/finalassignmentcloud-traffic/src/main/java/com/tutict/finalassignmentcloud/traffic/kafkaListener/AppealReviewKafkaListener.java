package com.tutict.finalassignmentcloud.traffic.kafkaListener;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentcloud.entity.AppealReview;
import com.tutict.finalassignmentcloud.traffic.service.AppealReviewService;
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
public class AppealReviewKafkaListener {

    private static final Logger log = Logger.getLogger(AppealReviewKafkaListener.class.getName());

    private final AppealReviewService appealReviewService;
    private final ObjectMapper objectMapper;

    @Autowired
    // 构造器注入依赖
    public AppealReviewKafkaListener(AppealReviewService appealReviewService,
                                     ObjectMapper objectMapper) {
        this.appealReviewService = appealReviewService;
        this.objectMapper = objectMapper;
    }

    // 监听 Kafka 消息（创建）
    @KafkaListener(topics = "appeal_review_create", groupId = "appealReviewGroup", concurrency = "3")
    public void onAppealReviewCreate(@Header(value = KafkaHeaders.RECEIVED_KEY, required = false) byte[] rawKey,
                                     @Payload String message) {
        log.log(Level.INFO, "Received Kafka message for AppealReview create: {0}", message);
        // 使用虚拟线程异步处理，避免阻塞监听线程
        Thread.ofVirtual().start(() -> processMessage(asKey(rawKey), message, "create"));
    }

    // 监听 Kafka 消息（更新）
    @KafkaListener(topics = "appeal_review_update", groupId = "appealReviewGroup", concurrency = "3")
    public void onAppealReviewUpdate(@Header(value = KafkaHeaders.RECEIVED_KEY, required = false) byte[] rawKey,
                                     @Payload String message) {
        log.log(Level.INFO, "Received Kafka message for AppealReview update: {0}", message);
        // 使用虚拟线程异步处理，避免阻塞监听线程
        Thread.ofVirtual().start(() -> processMessage(asKey(rawKey), message, "update"));
    }

    // 统一处理消息并执行业务逻辑
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

    // 反序列化消息体
    private AppealReview deserializeMessage(String message) {
        try {
            return objectMapper.readValue(message, AppealReview.class);
        } catch (Exception ex) {
            log.log(Level.SEVERE, "Failed to deserialize appeal review message: {0}", message);
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

