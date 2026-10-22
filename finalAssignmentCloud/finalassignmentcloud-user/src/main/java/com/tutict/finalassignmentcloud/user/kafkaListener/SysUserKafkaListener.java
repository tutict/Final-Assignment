package com.tutict.finalassignmentcloud.user.kafkaListener;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentcloud.entity.SysUser;
import com.tutict.finalassignmentcloud.reliability.IdempotencyConflictException;
import com.tutict.finalassignmentcloud.reliability.IdempotencyReplayException;
import com.tutict.finalassignmentcloud.reliability.HistoryReserve;
import com.tutict.finalassignmentcloud.user.service.SysUserService;
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
public class SysUserKafkaListener {

    private static final Logger log = Logger.getLogger(SysUserKafkaListener.class.getName());

    private final SysUserService sysUserService;
    private final ObjectMapper objectMapper;

    // 构造器注入依赖
    @Autowired
    public SysUserKafkaListener(SysUserService sysUserService, ObjectMapper objectMapper) {
        this.sysUserService = sysUserService;
        this.objectMapper = objectMapper;
    }

    // 监听 Kafka 消息（创建）
    @KafkaListener(topics = "sys_user_create", groupId = "sysUserGroup", concurrency = "3")
    public void onSysUserCreateReceived(@Header(value = KafkaHeaders.RECEIVED_KEY, required = false) byte[] rawKey,
                                        @Payload String message) {
        log.log(Level.INFO, "Received Kafka message for create");
        processMessage(asKey(rawKey), message, "create");
    }

    // 监听 Kafka 消息（更新）
    @KafkaListener(topics = "sys_user_update", groupId = "sysUserGroup", concurrency = "3")
    public void onSysUserUpdateReceived(@Header(value = KafkaHeaders.RECEIVED_KEY, required = false) byte[] rawKey,
                                        @Payload String message) {
        log.log(Level.INFO, "Received Kafka message for update");
        processMessage(asKey(rawKey), message, "update");
    }

    // 统一处理消息并执行业务逻辑
    private void processMessage(String idempotencyKey, String message, String action) {
        String key = idempotencyKey;
        if (isBlank(key)) {
            key = HistoryReserve.sha256(action + "|" + message);
            log.log(Level.WARNING, "SysUser event without key, using derived key {0}", key);
        }
        if (sysUserService.shouldSkipProcessing(key)) {
            log.log(Level.INFO, "Skipping duplicate SysUser event (key={0}, action={1})",
                    new Object[]{key, action});
            return;
        }
        SysUser entity = deserializeMessage(message);
        try {
            sysUserService.checkAndInsertIdempotency(key, entity, action);
        } catch (IdempotencyReplayException | IdempotencyConflictException ex) {
            log.log(Level.INFO, "Skipping already applied SysUser event (key={0})", key);
            return;
        }
        try {
            if ("create".equals(action)) {
                entity.setUserId(null);
                sysUserService.createSysUser(entity);
            } else if ("update".equals(action)) {
                sysUserService.updateSysUser(entity);
            } else {
                log.log(Level.WARNING, "Unsupported action: {0}", action);
                return;
            }
            sysUserService.markHistorySuccess(key, entity.getUserId());
            log.info(String.format("SysUser %s action processed successfully: %s", action, entity));
        } catch (Exception e) {
            sysUserService.markHistoryFailure(key, e.getMessage());
            log.log(Level.SEVERE, String.format("Error processing %s SysUser message: %s", action, message), e);
            throw new RuntimeException(String.format("Failed to process %s SysUser message", action), e);
        }
    }

    private String asKey(byte[] rawKey) {
        return rawKey == null ? null : new String(rawKey);
    }

    private boolean isBlank(String value) {
        return value == null || value.trim().isEmpty();
    }

    // 反序列化消息体
    private SysUser deserializeMessage(String message) {
        try {
            return objectMapper.readValue(message, SysUser.class);
        } catch (Exception e) {
            log.log(Level.SEVERE, "Failed to deserialize message: {0}", message);
            throw new RuntimeException("Failed to deserialize message", e);
        }
    }
}
