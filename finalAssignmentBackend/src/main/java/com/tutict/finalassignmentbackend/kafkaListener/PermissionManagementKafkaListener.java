package com.tutict.finalassignmentbackend.kafkaListener;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentbackend.entity.PermissionManagement;
import com.tutict.finalassignmentbackend.service.PermissionManagementService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.kafka.annotation.EnableKafka;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.logging.Level;
import java.util.logging.Logger;


// 定义一个Kafka消息监听器类，用于处理权限管理相关的Kafka消息
@Service
@EnableKafka
public class PermissionManagementKafkaListener {

    private static final Logger log = Logger.getLogger(PermissionManagementKafkaListener.class.getName());

    private final PermissionManagementService permissionManagementService;
    private final ObjectMapper objectMapper;

    @Autowired
    public PermissionManagementKafkaListener(PermissionManagementService permissionManagementService, ObjectMapper objectMapper) {
        this.permissionManagementService = permissionManagementService;
        this.objectMapper = objectMapper;
    }

    @KafkaListener(topics = "permission_create", groupId = "permissionGroup")
    @Transactional
    public void onPermissionCreateReceived(String message) {
        processMessage(message, "create", permissionManagementService::createPermission);
    }

    @KafkaListener(topics = "permission_update", groupId = "permissionGroup")
    @Transactional
    public void onPermissionUpdateReceived(String message) {
        processMessage(message, "update", permissionManagementService::updatePermission);
    }

    private void processMessage(String message, String action, MessageProcessor<PermissionManagement> processor) {
        try {
            PermissionManagement permission = deserializeMessage(message);
            if ("create".equals(action)) {
                permission.setPermissionId(null);
                processor.process(permission);
            }
            log.info(String.format("Permission %s action processed successfully: %s", action, message));
        } catch (Exception e) {
            log.log(Level.SEVERE, String.format("Error processing %s permission message: %s", action, message), e);
            throw new RuntimeException(String.format("Failed to process %s permission message", action), e);
        }
    }

    private PermissionManagement deserializeMessage(String message) {
        try {
            return objectMapper.readValue(message, PermissionManagement.class);
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