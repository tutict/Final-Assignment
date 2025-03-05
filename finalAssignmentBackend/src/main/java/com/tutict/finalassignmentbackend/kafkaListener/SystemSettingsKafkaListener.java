package com.tutict.finalassignmentbackend.kafkaListener;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentbackend.entity.SystemSettings;
import com.tutict.finalassignmentbackend.service.SystemSettingsService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.kafka.annotation.EnableKafka;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Service;

import java.util.logging.Level;
import java.util.logging.Logger;

// 系统设置的Kafka监听器组件
@Service
@EnableKafka
public class SystemSettingsKafkaListener {

    private static final Logger log = Logger.getLogger(SystemSettingsKafkaListener.class.getName());

    private final SystemSettingsService systemSettingsService;
    private final ObjectMapper objectMapper;

    @Autowired
    public SystemSettingsKafkaListener(SystemSettingsService systemSettingsService, ObjectMapper objectMapper) {
        this.systemSettingsService = systemSettingsService;
        this.objectMapper = objectMapper;
    }

    @KafkaListener(topics = "system_settings_update", groupId = "systemSettingsGroup", concurrency = "3")
    public void onSystemSettingsUpdateReceived(String message) {
        // 使用虚拟线程处理消息
        Thread.ofVirtual().start(() -> processMessage(message, systemSettingsService::updateSystemSettings));
    }

    private void processMessage(String message, MessageProcessor<SystemSettings> processor) {
        try {
            SystemSettings systemSettings = deserializeMessage(message);
            processor.process(systemSettings);
            log.info(String.format("System settings %s action processed successfully: %s", "update", message));
        } catch (Exception e) {
            log.log(Level.SEVERE, String.format("Error processing %s system settings message: %s", "update", message), e);
            throw new RuntimeException(String.format("Failed to process %s system settings message", "update"), e);
        }
    }

    private SystemSettings deserializeMessage(String message) {
        try {
            return objectMapper.readValue(message, SystemSettings.class);
        } catch (Exception e) {
            log.log(Level.SEVERE, "Failed to deserialize message: " + message, e);
            throw new RuntimeException("Failed to deserialize message", e);
        }
    }

    @FunctionalInterface
    private interface MessageProcessor<T> {
        void process(T t) throws Exception;
    }
}