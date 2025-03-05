package com.tutict.finalassignmentbackend.kafkaListener;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentbackend.entity.RoleManagement;
import com.tutict.finalassignmentbackend.service.RoleManagementService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.kafka.annotation.EnableKafka;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Service;

import java.util.logging.Level;
import java.util.logging.Logger;


@Service
@EnableKafka
public class RoleManagementKafkaListener {

    private static final Logger log = Logger.getLogger(RoleManagementKafkaListener.class.getName());

    private final RoleManagementService roleManagementService;
    private final ObjectMapper objectMapper;

    @Autowired
    public RoleManagementKafkaListener(RoleManagementService roleManagementService, ObjectMapper objectMapper) {
        this.roleManagementService = roleManagementService;
        this.objectMapper = objectMapper;
    }

    @KafkaListener(topics = "role_create", groupId = "roleGroup")
    public void onRoleCreateReceived(String message) {
        Thread.ofVirtual().start(() -> processMessage(message, "create", roleManagementService::createRole));
    }

    @KafkaListener(topics = "role_update", groupId = "roleGroup")
    public void onRoleUpdateReceived(String message) {
        Thread.ofVirtual().start(() -> processMessage(message, "update", roleManagementService::updateRole));
    }

    private void processMessage(String message, String action, MessageProcessor<RoleManagement> processor) {
        try {
            RoleManagement role = deserializeMessage(message);
            if ("create".equals(action)) {
                role.setRoleId(null);
            }
            processor.process(role);
            log.info(String.format("Role %s action processed successfully: %s", action, message));
        } catch (Exception e) {
            log.log(Level.SEVERE, String.format("Error processing %s role message: %s", action, message), e);
            throw new RuntimeException(String.format("Failed to process %s role message", action), e);
        }
    }

    private RoleManagement deserializeMessage(String message) {
        try {
            return objectMapper.readValue(message, RoleManagement.class);
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