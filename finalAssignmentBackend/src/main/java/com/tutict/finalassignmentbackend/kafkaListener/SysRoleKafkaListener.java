package com.tutict.finalassignmentbackend.kafkaListener;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentbackend.entity.SysRole;
import com.tutict.finalassignmentbackend.service.SysRoleService;
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
public class SysRoleKafkaListener {

    private static final Logger log = Logger.getLogger(SysRoleKafkaListener.class.getName());

    private final SysRoleService sysRoleService;
    private final ObjectMapper objectMapper;

    // 构造器注入依赖
    @Autowired
    public SysRoleKafkaListener(SysRoleService sysRoleService,
                                ObjectMapper objectMapper) {
        this.sysRoleService = sysRoleService;
        this.objectMapper = objectMapper;
    }

    // 监听 Kafka 消息
    @KafkaListener(topics = "sys_role_create", groupId = "sysRoleGroup", concurrency = "3")
    public void onSysRoleCreateReceived(@Header(value = KafkaHeaders.RECEIVED_KEY, required = false) byte[] rawKey,
                                        @Payload String message) {
        log.log(Level.INFO, "Received Kafka message for sys role create: {0}", message);
        // 使用虚拟线程异步处理，避免阻塞监听线程
        Thread.ofVirtual().start(() -> processMessage(asKey(rawKey), message, "create"));
    }

    // 监听 Kafka 消息
    @KafkaListener(topics = "sys_role_update", groupId = "sysRoleGroup", concurrency = "3")
    public void onSysRoleUpdateReceived(@Header(value = KafkaHeaders.RECEIVED_KEY, required = false) byte[] rawKey,
                                        @Payload String message) {
        log.log(Level.INFO, "Received Kafka message for sys role update: {0}", message);
        // 使用虚拟线程异步处理，避免阻塞监听线程
        Thread.ofVirtual().start(() -> processMessage(asKey(rawKey), message, "update"));
    }

    // 统一处理消息并执行业务逻辑
    private void processMessage(String idempotencyKey, String message, String action) {
        if (isBlank(idempotencyKey)) {
            log.warning("Received SysRole event without idempotency key, skipping");
            return;
        }
        try {
            SysRole payload = deserializeMessage(message);
            if (payload == null) {
                log.warning("Received SysRole event with empty payload, skipping");
                return;
            }
            if (sysRoleService.shouldSkipProcessing(idempotencyKey)) {
                log.log(Level.INFO, "Skipping duplicate SysRole event (key={0}, action={1})",
                        new Object[]{idempotencyKey, action});
                return;
            }
            SysRole result;
            if ("create".equalsIgnoreCase(action)) {
                payload.setRoleId(null);
                result = sysRoleService.createSysRole(payload);
            } else if ("update".equalsIgnoreCase(action)) {
                result = sysRoleService.updateSysRole(payload);
            } else {
                log.log(Level.WARNING, "Unsupported SysRole action: {0}", action);
                return;
            }
            sysRoleService.markHistorySuccess(idempotencyKey, result.getRoleId());
            log.info(String.format("SysRole %s action processed successfully (key=%s)", action, idempotencyKey));
        } catch (Exception ex) {
            sysRoleService.markHistoryFailure(idempotencyKey, ex.getMessage());
            log.log(Level.SEVERE,
                    String.format("Error processing %s SysRole message (key=%s): %s", action, idempotencyKey, message),
                    ex);
            throw ex;
        }
    }

    // 反序列化消息体
    private SysRole deserializeMessage(String message) {
        try {
            return objectMapper.readValue(message, SysRole.class);
        } catch (Exception ex) {
            log.log(Level.SEVERE, "Failed to deserialize SysRole message: {0}", message);
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
