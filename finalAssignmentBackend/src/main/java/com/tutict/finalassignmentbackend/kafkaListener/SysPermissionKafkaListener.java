package com.tutict.finalassignmentbackend.kafkaListener;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentbackend.entity.SysPermission;
import com.tutict.finalassignmentbackend.service.SysPermissionService;
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
public class SysPermissionKafkaListener {

    private static final Logger log = Logger.getLogger(SysPermissionKafkaListener.class.getName());

    private final SysPermissionService sysPermissionService;
    private final ObjectMapper objectMapper;

    // 构造器注入依赖
    @Autowired
    public SysPermissionKafkaListener(SysPermissionService sysPermissionService,
                                      ObjectMapper objectMapper) {
        this.sysPermissionService = sysPermissionService;
        this.objectMapper = objectMapper;
    }

    // 监听 Kafka 消息
    @KafkaListener(topics = "sys_permission_create", groupId = "sysPermissionGroup", concurrency = "3")
    public void onSysPermissionCreateReceived(@Header(value = KafkaHeaders.RECEIVED_KEY, required = false) byte[] rawKey,
                                              @Payload String message) {
        log.log(Level.INFO, "Received Kafka message for sys permission create: {0}", message);
        // 使用虚拟线程异步处理，避免阻塞监听线程
        Thread.ofVirtual().start(() -> processMessage(asKey(rawKey), message, "create"));
    }

    // 监听 Kafka 消息
    @KafkaListener(topics = "sys_permission_update", groupId = "sysPermissionGroup", concurrency = "3")
    public void onSysPermissionUpdateReceived(@Header(value = KafkaHeaders.RECEIVED_KEY, required = false) byte[] rawKey,
                                              @Payload String message) {
        log.log(Level.INFO, "Received Kafka message for sys permission update: {0}", message);
        // 使用虚拟线程异步处理，避免阻塞监听线程
        Thread.ofVirtual().start(() -> processMessage(asKey(rawKey), message, "update"));
    }

    // 统一处理消息并执行业务逻辑
    private void processMessage(String idempotencyKey, String message, String action) {
        if (isBlank(idempotencyKey)) {
            log.warning("Received SysPermission event without idempotency key, skipping");
            return;
        }
        try {
            SysPermission payload = deserializeMessage(message);
            if (payload == null) {
                log.warning("Received SysPermission event with empty payload, skipping");
                return;
            }
            if (sysPermissionService.shouldSkipProcessing(idempotencyKey)) {
                log.log(Level.INFO, "Skipping duplicate SysPermission event (key={0}, action={1})",
                        new Object[]{idempotencyKey, action});
                return;
            }
            SysPermission result;
            if ("create".equalsIgnoreCase(action)) {
                payload.setPermissionId(null);
                result = sysPermissionService.createSysPermission(payload);
            } else if ("update".equalsIgnoreCase(action)) {
                result = sysPermissionService.updateSysPermission(payload);
            } else {
                log.log(Level.WARNING, "Unsupported SysPermission action: {0}", action);
                return;
            }
            sysPermissionService.markHistorySuccess(idempotencyKey, result.getPermissionId());
            log.info(String.format("SysPermission %s action processed successfully (key=%s)", action, idempotencyKey));
        } catch (Exception ex) {
            sysPermissionService.markHistoryFailure(idempotencyKey, ex.getMessage());
            log.log(Level.SEVERE,
                    String.format("Error processing %s SysPermission message (key=%s): %s", action, idempotencyKey, message),
                    ex);
            throw ex;
        }
    }

    // 反序列化消息体
    private SysPermission deserializeMessage(String message) {
        try {
            return objectMapper.readValue(message, SysPermission.class);
        } catch (Exception ex) {
            log.log(Level.SEVERE, "Failed to deserialize SysPermission message: {0}", message);
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
