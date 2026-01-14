package com.tutict.finalassignmentcloud.system.kafkaListener;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentcloud.entity.SysSettings;
import com.tutict.finalassignmentcloud.system.mapper.SysSettingsMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.kafka.annotation.EnableKafka;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Service;

import java.util.logging.Level;
import java.util.logging.Logger;

@Service
@EnableKafka
// Kafka 监听器，处理消息
public class SysSettingsKafkaListener {

    private static final Logger log = Logger.getLogger(SysSettingsKafkaListener.class.getName());

    private final SysSettingsMapper sysSettingsMapper;
    private final ObjectMapper objectMapper;

    // 构造器注入依赖
    @Autowired
    public SysSettingsKafkaListener(SysSettingsMapper sysSettingsMapper, ObjectMapper objectMapper) {
        this.sysSettingsMapper = sysSettingsMapper;
        this.objectMapper = objectMapper;
    }

    // 监听 Kafka 消息（创建）
    @KafkaListener(topics = "sys_settings_create", groupId = "sysSettingsGroup", concurrency = "3")
    public void onSysSettingsCreateReceived(String message) {
        log.log(Level.INFO, "Received Kafka message for create: {0}", message);
        // 使用虚拟线程异步处理，避免阻塞监听线程
        Thread.ofVirtual().start(() -> processMessage(message, "create"));
    }

    // 监听 Kafka 消息（更新）
    @KafkaListener(topics = "sys_settings_update", groupId = "sysSettingsGroup", concurrency = "3")
    public void onSysSettingsUpdateReceived(String message) {
        log.log(Level.INFO, "Received Kafka message for update: {0}", message);
        // 使用虚拟线程异步处理，避免阻塞监听线程
        Thread.ofVirtual().start(() -> processMessage(message, "update"));
    }

    // 统一处理消息并执行业务逻辑
    private void processMessage(String message, String action) {
        try {
            SysSettings entity = deserializeMessage(message);
            if ("create".equals(action)) {
                entity.setSettingId(null);
                sysSettingsMapper.insert(entity);
            } else if ("update".equals(action)) {
                sysSettingsMapper.updateById(entity);
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