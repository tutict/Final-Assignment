package com.tutict.finalassignmentbackend.kafkaListener;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentbackend.entity.OperationLog;
import com.tutict.finalassignmentbackend.service.OperationLogService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.kafka.annotation.EnableKafka;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Service;

import java.util.logging.Level;
import java.util.logging.Logger;


@Service
@EnableKafka
public class OperationLogKafkaListener {

    private static final Logger log = Logger.getLogger(OperationLogKafkaListener.class.getName());

    private final OperationLogService operationLogService;
    private final ObjectMapper objectMapper;

    @Autowired
    public OperationLogKafkaListener(OperationLogService operationLogService, ObjectMapper objectMapper) {
        this.operationLogService = operationLogService;
        this.objectMapper = objectMapper;
    }

    @KafkaListener(topics = "operation_create", groupId = "operationLogGroup")
    public void onOperationLogCreateReceived(String message) {
        Thread.ofVirtual().start(() -> processMessage(message, "create", operationLogService::createOperationLog));
    }

    @KafkaListener(topics = "operation_update", groupId = "operationLogGroup")
    public void onOperationLogUpdateReceived(String message) {
        Thread.ofVirtual().start(() -> processMessage(message, "update", operationLogService::updateOperationLog));
    }

    private void processMessage(String message, String action, MessageProcessor<OperationLog> processor) {
        try {
            OperationLog operationLog = deserializeMessage(message);
            if ("create".equals(action)) {
                operationLog.setLogId(null);
            }
            processor.process(operationLog);
            log.info(String.format("Operation log %s action processed successfully: %s", action, message));
        } catch (Exception e) {
            log.log(Level.SEVERE, String.format("Error processing %s operation log message: %s", action, message), e);
            throw new RuntimeException(String.format("Failed to process %s operation log message", action), e);
        }
    }

    private OperationLog deserializeMessage(String message) {
        try {
            return objectMapper.readValue(message, OperationLog.class);
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