package com.tutict.finalassignmentbackend.kafkaListener;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentbackend.entity.SysSettings;
import com.tutict.finalassignmentbackend.service.SysSettingsService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.kafka.annotation.EnableKafka;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.kafka.support.Acknowledgment;
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

    // 监听 Kafka 消息
    @KafkaListener(topics = "sys_settings_create", groupId = "sysSettingsGroup", concurrency = "3")
    public void onSysSettingsCreateReceived(String message, Acknowledgment ack) {
        log.log(Level.INFO, "Received Kafka message for create (payload omitted)");
        processMessage(message, "create");
        ack.acknowledge();
    }

    // 监听 Kafka 消息
    @KafkaListener(topics = "sys_settings_update", groupId = "sysSettingsGroup", concurrency = "3")
    public void onSysSettingsUpdateReceived(String message, Acknowledgment ack) {
        log.log(Level.INFO, "Received Kafka message for update (payload omitted)");
        processMessage(message, "update");
        ack.acknowledge();
    }

    // 统一处理消息并执行业务逻辑
    private void processMessage(String message, String action) {
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
            log.info(String.format("SysSettings %s action processed successfully", action));
        } catch (Exception e) {
            log.log(Level.SEVERE, String.format("Error processing %s SysSettings message (payload omitted)", action), e);
            throw new RuntimeException(String.format("Failed to process %s SysSettings message", action), e);
        }
    }
    private SysSettings deserializeMessage(String message) {
        try {
            return objectMapper.readValue(message, SysSettings.class);
        } catch (Exception e) {
            log.log(Level.SEVERE, "Failed to deserialize message (payload omitted)");
            throw new RuntimeException("Failed to deserialize message", e);
        }
    }
}
