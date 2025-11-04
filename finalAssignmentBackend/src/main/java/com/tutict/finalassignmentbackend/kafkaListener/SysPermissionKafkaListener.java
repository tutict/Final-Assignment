package com.tutict.finalassignmentbackend.kafkaListener;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentbackend.entity.SysPermission;
import com.tutict.finalassignmentbackend.mapper.SysPermissionMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.kafka.annotation.EnableKafka;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Service;

import java.util.logging.Level;
import java.util.logging.Logger;

@Service
@EnableKafka
public class SysPermissionKafkaListener {

    private static final Logger log = Logger.getLogger(SysPermissionKafkaListener.class.getName());

    private final SysPermissionMapper sysPermissionMapper;
    private final ObjectMapper objectMapper;

    @Autowired
    public SysPermissionKafkaListener(SysPermissionMapper sysPermissionMapper, ObjectMapper objectMapper) {
        this.sysPermissionMapper = sysPermissionMapper;
        this.objectMapper = objectMapper;
    }

    @KafkaListener(topics = "sys_permission_create", groupId = "sysPermissionGroup", concurrency = "3")
    public void onSysPermissionCreateReceived(String message) {
        log.log(Level.INFO, "Received Kafka message for create: {0}", message);
        Thread.ofVirtual().start(() -> processMessage(message, "create"));
    }

    @KafkaListener(topics = "sys_permission_update", groupId = "sysPermissionGroup", concurrency = "3")
    public void onSysPermissionUpdateReceived(String message) {
        log.log(Level.INFO, "Received Kafka message for update: {0}", message);
        Thread.ofVirtual().start(() -> processMessage(message, "update"));
    }

    private void processMessage(String message, String action) {
        try {
            SysPermission entity = deserializeMessage(message);
            if ("create".equals(action)) {
                entity.setPermissionId(null);
                sysPermissionMapper.insert(entity);
            } else if ("update".equals(action)) {
                sysPermissionMapper.updateById(entity);
            } else {
                log.log(Level.WARNING, "Unsupported action: {0}", action);
                return;
            }
            log.info(String.format("SysPermission %s action processed successfully: %s", action, entity));
        } catch (Exception e) {
            log.log(Level.SEVERE, String.format("Error processing %s SysPermission message: %s", action, message), e);
            throw new RuntimeException(String.format("Failed to process %s SysPermission message", action), e);
        }
    }

    private SysPermission deserializeMessage(String message) {
        try {
            return objectMapper.readValue(message, SysPermission.class);
        } catch (Exception e) {
            log.log(Level.SEVERE, "Failed to deserialize message: {0}", message);
            throw new RuntimeException("Failed to deserialize message", e);
        }
    }
}
