package com.tutict.finalassignmentcloud.system.kafkaListener;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentcloud.entity.SysSettings;
import com.tutict.finalassignmentcloud.system.service.SysSettingsService;
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
public class SysSettingsKafkaListener {

    private static final Logger log = Logger.getLogger(SysSettingsKafkaListener.class.getName());

    private final SysSettingsService sysSettingsService;
    private final ObjectMapper objectMapper;

    // 构造器注入依赖
    @Autowired
    public SysSettingsKafkaListener(SysSettingsService sysSettingsService, ObjectMapper objectMapper) {
        this.sysSettingsService = sysSettingsService;
        this.objectMapper = objectMapper;
    }

    // 监听 Kafka 消息（创建）
    @KafkaListener(topics = "sys_settings_create", groupId = "sysSettingsGroup", concurrency = "3")
    public void onSysSettingsCreateReceived(@Header(value = KafkaHeaders.RECEIVED_KEY, required = false) byte[] rawKey,
                                            @Payload String message) {
        log.log(Level.INFO, "Received Kafka message for create");
        // 使用虚拟线程异步处理，避免阻塞监听线程
        Thread.ofVirtual().start(() -> processMessage(asKey(rawKey), message, "create"));
    }

    // 监听 Kafka 消息（更新）
    @KafkaListener(topics = "sys_settings_update", groupId = "sysSettingsGroup", concurrency = "3")
    public void onSysSettingsUpdateReceived(@Header(value = KafkaHeaders.RECEIVED_KEY, required = false) byte[] rawKey,
                                            @Payload String message) {
        log.log(Level.INFO, "Received Kafka message for update");
        // 使用虚拟线程异步处理，避免阻塞监听线程
        Thread.ofVirtual().start(() -> processMessage(asKey(rawKey), message, "update"));
    }

    // 统一处理消息并执行业务逻辑
    private void processMessage(String idempotencyKey, String message, String action) {
        if (isBlank(idempotencyKey)) {
            log.warning("Received SysSettings event without idempotency key, skipping");
            return;
        }
        if (sysSettingsService.shouldSkipProcessing(idempotencyKey)) {
            log.log(Level.INFO, "Skipping duplicate SysSettings event (key={0}, action={1})",
                    new Object[]{idempotencyKey, action});
            return;
        }
        try {
            SysSettings entity = deserializeMessage(message);
            if ("create".equals(action)) {
                entity.setSettingId(null);
                sysSettingsService.createSysSettings(entity);
            } else if ("update".equals(action)) {
                sysSettingsService.updateSysSettings(entity);
            } else {
                log.log(Level.WARNING, "Unsupported action: {0}", action);
                return;
            }
            log.info(String.format("SysSettings %s action processed successfully: %s", action, entity));
        } catch (Exception e) {
            log.log(Level.SEVERE, String.format("Error processing %s SysSettings message: %s", action, message), e);
            throw new RuntimeException(String.format("Failed to process %s SysSettings message", action), e);
        }
    }

    private String asKey(byte[] rawKey) {
        return rawKey == null ? null : new String(rawKey);
    }

    private boolean isBlank(String value) {
        return value == null || value.trim().isEmpty();
    }

    // 反序列化消息体
    private SysSettings deserializeMessage(String message) {
        try {
            return objectMapper.readValue(message, SysSettings.class);
        } catch (Exception e) {
            log.log(Level.SEVERE, "Failed to deserialize message: {0}", message);
            throw new RuntimeException("Failed to deserialize message", e);
        }
    }
}
