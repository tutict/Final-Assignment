package com.tutict.finalassignmentbackend.kafkaListener;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentbackend.entity.SysRolePermission;
import com.tutict.finalassignmentbackend.mapper.SysRolePermissionMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.kafka.annotation.EnableKafka;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Service;

import java.util.logging.Level;
import java.util.logging.Logger;

@Service
@EnableKafka
public class SysRolePermissionKafkaListener {

    private static final Logger log = Logger.getLogger(SysRolePermissionKafkaListener.class.getName());

    private final SysRolePermissionMapper sysRolePermissionMapper;
    private final ObjectMapper objectMapper;

    @Autowired
    public SysRolePermissionKafkaListener(SysRolePermissionMapper sysRolePermissionMapper, ObjectMapper objectMapper) {
        this.sysRolePermissionMapper = sysRolePermissionMapper;
        this.objectMapper = objectMapper;
    }

    @KafkaListener(topics = "sys_role_permission_create", groupId = "sysRolePermissionGroup", concurrency = "3")
    public void onSysRolePermissionCreateReceived(String message) {
        log.log(Level.INFO, "Received Kafka message for create: {0}", message);
        Thread.ofVirtual().start(() -> processMessage(message, "create"));
    }

    @KafkaListener(topics = "sys_role_permission_update", groupId = "sysRolePermissionGroup", concurrency = "3")
    public void onSysRolePermissionUpdateReceived(String message) {
        log.log(Level.INFO, "Received Kafka message for update: {0}", message);
        Thread.ofVirtual().start(() -> processMessage(message, "update"));
    }

    private void processMessage(String message, String action) {
        try {
            SysRolePermission entity = deserializeMessage(message);
            if ("create".equals(action)) {
                entity.setId(null);
                sysRolePermissionMapper.insert(entity);
            } else if ("update".equals(action)) {
                sysRolePermissionMapper.updateById(entity);
            } else {
                log.log(Level.WARNING, "Unsupported action: {0}", action);
                return;
            }
            log.info(String.format("SysRolePermission %s action processed successfully: %s", action, entity));
        } catch (Exception e) {
            log.log(Level.SEVERE, String.format("Error processing %s SysRolePermission message: %s", action, message), e);
            throw new RuntimeException(String.format("Failed to process %s SysRolePermission message", action), e);
        }
    }

    private SysRolePermission deserializeMessage(String message) {
        try {
            return objectMapper.readValue(message, SysRolePermission.class);
        } catch (Exception e) {
            log.log(Level.SEVERE, "Failed to deserialize message: {0}", message);
            throw new RuntimeException("Failed to deserialize message", e);
        }
    }
}
