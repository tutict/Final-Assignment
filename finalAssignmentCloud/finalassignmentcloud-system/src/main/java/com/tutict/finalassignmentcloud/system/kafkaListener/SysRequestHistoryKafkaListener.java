package com.tutict.finalassignmentcloud.system.kafkaListener;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentcloud.entity.SysRequestHistory;
import com.tutict.finalassignmentcloud.system.service.SysRequestHistoryService;
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
public class SysRequestHistoryKafkaListener {

    private static final Logger log = Logger.getLogger(SysRequestHistoryKafkaListener.class.getName());

    private final SysRequestHistoryService sysRequestHistoryService;
    private final ObjectMapper objectMapper;

    // 构造器注入依赖
    @Autowired
    public SysRequestHistoryKafkaListener(SysRequestHistoryService sysRequestHistoryService,
                                          ObjectMapper objectMapper) {
        this.sysRequestHistoryService = sysRequestHistoryService;
        this.objectMapper = objectMapper;
    }

    // 监听 Kafka 消息（创建）
    @KafkaListener(topics = "sys_request_history_create", groupId = "sysRequestHistoryGroup", concurrency = "3")
    public void onSysRequestHistoryCreateReceived(
            @Header(value = KafkaHeaders.RECEIVED_KEY, required = false) byte[] rawKey,
            @Payload String message) {
        log.log(Level.INFO, "Received Kafka message for sys request history create: {0}", message);
        // 使用虚拟线程异步处理，避免阻塞监听线程
        Thread.ofVirtual().start(() -> processMessage(asKey(rawKey), message, "create"));
    }

    // 监听 Kafka 消息（更新）
    @KafkaListener(topics = "sys_request_history_update", groupId = "sysRequestHistoryGroup", concurrency = "3")
    public void onSysRequestHistoryUpdateReceived(
            @Header(value = KafkaHeaders.RECEIVED_KEY, required = false) byte[] rawKey,
            @Payload String message) {
        log.log(Level.INFO, "Received Kafka message for sys request history update: {0}", message);
        // 使用虚拟线程异步处理，避免阻塞监听线程
        Thread.ofVirtual().start(() -> processMessage(asKey(rawKey), message, "update"));
    }

    // 统一处理消息并执行业务逻辑
    private void processMessage(String idempotencyKey, String message, String action) {
        if (isBlank(idempotencyKey)) {
            log.warning("Received SysRequestHistory event without idempotency key, skipping");
            return;
        }
        try {
            SysRequestHistory payload = deserializeMessage(message);
            if (payload == null) {
                log.warning("Received SysRequestHistory event with empty payload, skipping");
                return;
            }
            if (sysRequestHistoryService.shouldSkipProcessing(idempotencyKey)) {
                log.log(Level.INFO, "Skipping duplicate SysRequestHistory event (key={0}, action={1})",
                        new Object[]{idempotencyKey, action});
                return;
            }
            SysRequestHistory result;
            if ("create".equalsIgnoreCase(action)) {
                payload.setId(null);
                result = sysRequestHistoryService.createSysRequestHistory(payload);
            } else if ("update".equalsIgnoreCase(action)) {
                result = sysRequestHistoryService.updateSysRequestHistory(payload);
            } else {
                log.log(Level.WARNING, "Unsupported SysRequestHistory action: {0}", action);
                return;
            }
            sysRequestHistoryService.markHistorySuccess(idempotencyKey, result.getId());
            log.info(String.format("SysRequestHistory %s action processed successfully (key=%s)", action, idempotencyKey));
        } catch (Exception ex) {
            sysRequestHistoryService.markHistoryFailure(idempotencyKey, ex.getMessage());
            log.log(Level.SEVERE,
                    String.format("Error processing %s SysRequestHistory message (key=%s): %s", action, idempotencyKey, message),
                    ex);
            throw ex;
        }
    }

    // 反序列化消息体
    private SysRequestHistory deserializeMessage(String message) {
        try {
            return objectMapper.readValue(message, SysRequestHistory.class);
        } catch (Exception ex) {
            log.log(Level.SEVERE, "Failed to deserialize SysRequestHistory message: {0}", message);
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