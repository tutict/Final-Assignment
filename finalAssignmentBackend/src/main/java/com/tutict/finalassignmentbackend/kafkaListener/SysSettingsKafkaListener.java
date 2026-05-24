package com.tutict.finalassignmentbackend.kafkaListener;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentbackend.entity.system.SysSettings;
import com.tutict.finalassignmentbackend.service.admin.SysSettingsService;
import org.apache.kafka.clients.consumer.ConsumerRecord;
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
    @KafkaListener(topics = "${kafka.topics.sys-settings.create:sys_settings_create}", groupId = "${kafka.groups.sys-settings:sysSettingsGroup}", concurrency = "3")
    public void onSysSettingsCreateReceived(ConsumerRecord<String, String> record, Acknowledgment ack) {
        log.log(Level.INFO, "Received Kafka message for create (payload omitted)");
        processRecord(record, "create", ack);
    }

    // 监听 Kafka 消息
    @KafkaListener(topics = "${kafka.topics.sys-settings.update:sys_settings_update}", groupId = "${kafka.groups.sys-settings:sysSettingsGroup}", concurrency = "3")
    public void onSysSettingsUpdateReceived(ConsumerRecord<String, String> record, Acknowledgment ack) {
        log.log(Level.INFO, "Received Kafka message for update (payload omitted)");
        processRecord(record, "update", ack);
    }

    private void processRecord(ConsumerRecord<String, String> record, String action, Acknowledgment ack) {
        String idempotencyKey = record.key();
        if (idempotencyKey != null && sysSettingsService.shouldSkipProcessing(idempotencyKey)) {
            log.log(Level.INFO, "Skipping duplicate SysSettings message: key={0}", idempotencyKey);
            ack.acknowledge();
            return;
        }
        try {
            SysSettings entity = processMessage(record.value(), action);
            if (idempotencyKey != null) {
                sysSettingsService.markHistorySuccess(idempotencyKey, entity.getSettingId());
            }
            ack.acknowledge();
        } catch (Exception e) {
            if (idempotencyKey != null) {
                sysSettingsService.markHistoryFailure(idempotencyKey, e.getMessage());
            }
            log.log(Level.SEVERE, "SysSettings message processing failed", e);
            throw e;
        }
    }

    // 统一处理消息并执行业务逻辑
    private SysSettings processMessage(String message, String action) {
        try {
            SysSettings entity = deserializeMessage(message);
            if ("create".equals(action)) {
                entity.setSettingId(null);
                entity = sysSettingsService.createSysSettings(entity);
            } else if ("update".equals(action)) {
                entity = sysSettingsService.updateSysSettings(entity);
            } else {
                log.log(Level.WARNING, "Unsupported action: {0}", action);
                return entity;
            }
            log.info(String.format("SysSettings %s action processed successfully", action));
            return entity;
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
