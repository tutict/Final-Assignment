package com.tutict.finalassignmentbackend.kafkaListener;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentbackend.entity.SysRequestHistory;
import com.tutict.finalassignmentbackend.mapper.SysRequestHistoryMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.kafka.annotation.EnableKafka;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Service;

import java.util.logging.Level;
import java.util.logging.Logger;

@Service
@EnableKafka
public class SysRequestHistoryKafkaListener {

    private static final Logger log = Logger.getLogger(SysRequestHistoryKafkaListener.class.getName());

    private final SysRequestHistoryMapper sysRequestHistoryMapper;
    private final ObjectMapper objectMapper;

    @Autowired
    public SysRequestHistoryKafkaListener(SysRequestHistoryMapper sysRequestHistoryMapper, ObjectMapper objectMapper) {
        this.sysRequestHistoryMapper = sysRequestHistoryMapper;
        this.objectMapper = objectMapper;
    }

    @KafkaListener(topics = "sys_request_history_create", groupId = "sysRequestHistoryGroup", concurrency = "3")
    public void onSysRequestHistoryCreateReceived(String message) {
        log.log(Level.INFO, "Received Kafka message for create: {0}", message);
        Thread.ofVirtual().start(() -> processMessage(message, "create"));
    }

    @KafkaListener(topics = "sys_request_history_update", groupId = "sysRequestHistoryGroup", concurrency = "3")
    public void onSysRequestHistoryUpdateReceived(String message) {
        log.log(Level.INFO, "Received Kafka message for update: {0}", message);
        Thread.ofVirtual().start(() -> processMessage(message, "update"));
    }

    private void processMessage(String message, String action) {
        try {
            SysRequestHistory entity = deserializeMessage(message);
            if ("create".equals(action)) {
                entity.setId(null);
                sysRequestHistoryMapper.insert(entity);
            } else if ("update".equals(action)) {
                sysRequestHistoryMapper.updateById(entity);
            } else {
                log.log(Level.WARNING, "Unsupported action: {0}", action);
                return;
            }
            log.info(String.format("SysRequestHistory %s action processed successfully: %s", action, entity));
        } catch (Exception e) {
            log.log(Level.SEVERE, String.format("Error processing %s SysRequestHistory message: %s", action, message), e);
            throw new RuntimeException(String.format("Failed to process %s SysRequestHistory message", action), e);
        }
    }

    private SysRequestHistory deserializeMessage(String message) {
        try {
            return objectMapper.readValue(message, SysRequestHistory.class);
        } catch (Exception e) {
            log.log(Level.SEVERE, "Failed to deserialize message: {0}", message);
            throw new RuntimeException("Failed to deserialize message", e);
        }
    }
}
