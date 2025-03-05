package com.tutict.finalassignmentbackend.kafkaListener;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentbackend.entity.UserManagement;
import com.tutict.finalassignmentbackend.service.UserManagementService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.kafka.annotation.EnableKafka;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Service;

import java.util.logging.Level;
import java.util.logging.Logger;

@Service
@EnableKafka
public class UserManagementKafkaListener {

    private static final Logger log = Logger.getLogger(UserManagementKafkaListener.class.getName());

    private final UserManagementService userManagementService;
    private final ObjectMapper objectMapper;

    @Autowired
    public UserManagementKafkaListener(UserManagementService userManagementService, ObjectMapper objectMapper) {
        this.userManagementService = userManagementService;
        this.objectMapper = objectMapper;
    }

    @KafkaListener(topics = "user_create", groupId = "userGroup", concurrency = "3")
    public void onUserCreateReceived(String message) {
        // 使用虚拟线程处理消息
        Thread.ofVirtual().start(() -> processMessage(message, "create", userManagementService::createUser));
    }

    @KafkaListener(topics = "user_update", groupId = "userGroup", concurrency = "3")
    public void onUserUpdateReceived(String message) {
        // 使用虚拟线程处理消息
        Thread.ofVirtual().start(() -> processMessage(message, "update", userManagementService::updateUser));
    }

    private void processMessage(String message, String action, MessageProcessor<UserManagement> processor) {
        try {
            UserManagement user = deserializeMessage(message);
            if ("create".equals(action)) {
                // 让数据库自增
                user.setUserId(null);
            }
            processor.process(user);
            log.info(String.format("User %s action processed successfully: %s", action, message));
        } catch (Exception e) {
            log.log(Level.SEVERE, String.format("Error processing %s user message: %s", action, message), e);
            throw new RuntimeException(String.format("Failed to process %s user message", action), e);
        }
    }

    private UserManagement deserializeMessage(String message) {
        try {
            return objectMapper.readValue(message, UserManagement.class);
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