package com.tutict.finalassignmentbackend.kafkaListener;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentbackend.entity.SysRole;
import com.tutict.finalassignmentbackend.mapper.SysRoleMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.kafka.annotation.EnableKafka;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Service;

import java.util.logging.Level;
import java.util.logging.Logger;

@Service
@EnableKafka
public class SysRoleKafkaListener {

    private static final Logger log = Logger.getLogger(SysRoleKafkaListener.class.getName());

    private final SysRoleMapper sysRoleMapper;
    private final ObjectMapper objectMapper;

    @Autowired
    public SysRoleKafkaListener(SysRoleMapper sysRoleMapper, ObjectMapper objectMapper) {
        this.sysRoleMapper = sysRoleMapper;
        this.objectMapper = objectMapper;
    }

    @KafkaListener(topics = "sys_role_create", groupId = "sysRoleGroup", concurrency = "3")
    public void onSysRoleCreateReceived(String message) {
        log.log(Level.INFO, "Received Kafka message for create: {0}", message);
        Thread.ofVirtual().start(() -> processMessage(message, "create"));
    }

    @KafkaListener(topics = "sys_role_update", groupId = "sysRoleGroup", concurrency = "3")
    public void onSysRoleUpdateReceived(String message) {
        log.log(Level.INFO, "Received Kafka message for update: {0}", message);
        Thread.ofVirtual().start(() -> processMessage(message, "update"));
    }

    private void processMessage(String message, String action) {
        try {
            SysRole entity = deserializeMessage(message);
            if ("create".equals(action)) {
                entity.setRoleId(null);
                sysRoleMapper.insert(entity);
            } else if ("update".equals(action)) {
                sysRoleMapper.updateById(entity);
            } else {
                log.log(Level.WARNING, "Unsupported action: {0}", action);
                return;
            }
            log.info(String.format("SysRole %s action processed successfully: %s", action, entity));
        } catch (Exception e) {
            log.log(Level.SEVERE, String.format("Error processing %s SysRole message: %s", action, message), e);
            throw new RuntimeException(String.format("Failed to process %s SysRole message", action), e);
        }
    }

    private SysRole deserializeMessage(String message) {
        try {
            return objectMapper.readValue(message, SysRole.class);
        } catch (Exception e) {
            log.log(Level.SEVERE, "Failed to deserialize message: {0}", message);
            throw new RuntimeException("Failed to deserialize message", e);
        }
    }
}
