package com.tutict.finalassignmentcloud.user.kafkaListener;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentcloud.entity.SysUserRole;
import com.tutict.finalassignmentcloud.user.service.SysUserRoleService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.kafka.annotation.EnableKafka;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.kafka.support.KafkaHeaders;
import org.springframework.messaging.handler.annotation.Header;
import org.springframework.messaging.handler.annotation.Payload;
import org.springframework.stereotype.Service;

import java.util.logging.Level;
import java.util.logging.Logger;

@Service
@EnableKafka
// Kafka 监听器，处理消息
public class SysUserRoleKafkaListener {

    private static final Logger log = Logger.getLogger(SysUserRoleKafkaListener.class.getName());

    private final SysUserRoleService sysUserRoleService;
    private final ObjectMapper objectMapper;

    // 构造器注入依赖
    @Autowired
    public SysUserRoleKafkaListener(SysUserRoleService sysUserRoleService, ObjectMapper objectMapper) {
        this.sysUserRoleService = sysUserRoleService;
        this.objectMapper = objectMapper;
    }

    // 监听 Kafka 消息（创建）
    @KafkaListener(topics = "sys_user_role_create", groupId = "sysUserRoleGroup", concurrency = "3")
    public void onSysUserRoleCreateReceived(@Header(value = KafkaHeaders.RECEIVED_KEY, required = false) byte[] rawKey,
                                            @Payload String message) {
        log.log(Level.INFO, "Received Kafka message for create");
        processMessage(asKey(rawKey), message, "create");
    }

    // 监听 Kafka 消息（更新）
    @KafkaListener(topics = "sys_user_role_update", groupId = "sysUserRoleGroup", concurrency = "3")
    public void onSysUserRoleUpdateReceived(@Header(value = KafkaHeaders.RECEIVED_KEY, required = false) byte[] rawKey,
                                            @Payload String message) {
        log.log(Level.INFO, "Received Kafka message for update");
        processMessage(asKey(rawKey), message, "update");
    }

    // 统一处理消息并执行业务逻辑
    private void processMessage(String idempotencyKey, String message, String action) {
        if (isBlank(idempotencyKey)) {
            log.warning("Received SysUserRole event without idempotency key, skipping");
            return;
        }
        if (sysUserRoleService.shouldSkipProcessing(idempotencyKey)) {
            log.log(Level.INFO, "Skipping duplicate SysUserRole event (key={0}, action={1})",
                    new Object[]{idempotencyKey, action});
            return;
        }
        try {
            SysUserRole entity = deserializeMessage(message);
            if ("create".equals(action)) {
                entity.setId(null);
                sysUserRoleService.createRelation(entity);
            } else if ("update".equals(action)) {
                sysUserRoleService.updateRelation(entity);
            } else {
                log.log(Level.WARNING, "Unsupported action: {0}", action);
                return;
            }
            log.info(String.format("SysUserRole %s action processed successfully: %s", action, entity));
        } catch (Exception e) {
            log.log(Level.SEVERE, String.format("Error processing %s SysUserRole message: %s", action, message), e);
            throw new RuntimeException(String.format("Failed to process %s SysUserRole message", action), e);
        }
    }

    private String asKey(byte[] rawKey) {
        return rawKey == null ? null : new String(rawKey);
    }

    private boolean isBlank(String value) {
        return value == null || value.trim().isEmpty();
    }

    // 反序列化消息体
    private SysUserRole deserializeMessage(String message) {
        try {
            return objectMapper.readValue(message, SysUserRole.class);
        } catch (Exception e) {
            log.log(Level.SEVERE, "Failed to deserialize message: {0}", message);
            throw new RuntimeException("Failed to deserialize message", e);
        }
    }
}
