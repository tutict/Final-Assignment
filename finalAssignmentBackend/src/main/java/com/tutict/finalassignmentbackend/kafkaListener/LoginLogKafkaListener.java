package com.tutict.finalassignmentbackend.kafkaListener;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentbackend.entity.LoginLog;
import com.tutict.finalassignmentbackend.service.LoginLogService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.kafka.annotation.EnableKafka;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.logging.Level;
import java.util.logging.Logger;


@Service
@EnableKafka
public class LoginLogKafkaListener {

    private static final Logger log = Logger.getLogger(LoginLogKafkaListener.class.getName());

    private final LoginLogService loginLogService;
    private final ObjectMapper objectMapper;

    @Autowired
    public LoginLogKafkaListener(LoginLogService loginLogService, ObjectMapper objectMapper) {
        this.loginLogService = loginLogService;
        this.objectMapper = objectMapper;
    }

    @KafkaListener(topics = "login_create", groupId = "loginLogGroup")
    @Transactional
    public void onLoginLogCreateReceived(String message) {
        processMessage(message, "create", loginLogService::createLoginLog);
    }

    @KafkaListener(topics = "login_update", groupId = "loginLogGroup")
    @Transactional
    public void onLoginLogUpdateReceived(String message) {
        processMessage(message, "update", loginLogService::updateLoginLog);
    }

    private void processMessage(String message, String action, MessageProcessor<LoginLog> processor) {
        try {
            LoginLog loginLog = deserializeMessage(message);
            if ("create".equals(action)) {
                loginLog.setLogId(null);
                processor.process(loginLog);
            }
            log.info(String.format("Login log %s action processed successfully: %s", action, message));
        } catch (Exception e) {
            log.log(Level.SEVERE, String.format("Error processing %s login log message: %s", action, message), e);
            throw new RuntimeException(String.format("Failed to process %s login log message", action), e);
        }
    }

    private LoginLog deserializeMessage(String message) {
        try {
            return objectMapper.readValue(message, LoginLog.class);
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