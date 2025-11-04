package com.tutict.finalassignmentbackend.kafkaListener;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentbackend.entity.AuditOperationLog;
import com.tutict.finalassignmentbackend.mapper.AuditOperationLogMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.kafka.annotation.EnableKafka;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Service;

import java.util.logging.Level;
import java.util.logging.Logger;

@Service
@EnableKafka
public class AuditOperationLogKafkaListener {

    private static final Logger log = Logger.getLogger(AuditOperationLogKafkaListener.class.getName());

    private final AuditOperationLogMapper auditOperationLogMapper;
    private final ObjectMapper objectMapper;

    @Autowired
    public AuditOperationLogKafkaListener(AuditOperationLogMapper auditOperationLogMapper, ObjectMapper objectMapper) {
        this.auditOperationLogMapper = auditOperationLogMapper;
        this.objectMapper = objectMapper;
    }

    @KafkaListener(topics = "audit_operation_log_create", groupId = "auditOperationLogGroup", concurrency = "3")
    public void onAuditOperationLogCreateReceived(String message) {
        log.log(Level.INFO, "Received Kafka message for create: {0}", message);
        Thread.ofVirtual().start(() -> processMessage(message, "create"));
    }

    @KafkaListener(topics = "audit_operation_log_update", groupId = "auditOperationLogGroup", concurrency = "3")
    public void onAuditOperationLogUpdateReceived(String message) {
        log.log(Level.INFO, "Received Kafka message for update: {0}", message);
        Thread.ofVirtual().start(() -> processMessage(message, "update"));
    }

    private void processMessage(String message, String action) {
        try {
            AuditOperationLog entity = deserializeMessage(message);
            if ("create".equals(action)) {
                entity.setLogId(null);
                auditOperationLogMapper.insert(entity);
            } else if ("update".equals(action)) {
                auditOperationLogMapper.updateById(entity);
            } else {
                log.log(Level.WARNING, "Unsupported action: {0}", action);
                return;
            }
            log.info(String.format("AuditOperationLog %s action processed successfully: %s", action, entity));
        } catch (Exception e) {
            log.log(Level.SEVERE, String.format("Error processing %s AuditOperationLog message: %s", action, message), e);
            throw new RuntimeException(String.format("Failed to process %s AuditOperationLog message", action), e);
        }
    }

    private AuditOperationLog deserializeMessage(String message) {
        try {
            return objectMapper.readValue(message, AuditOperationLog.class);
        } catch (Exception e) {
            log.log(Level.SEVERE, "Failed to deserialize message: {0}", message);
            throw new RuntimeException("Failed to deserialize message", e);
        }
    }
}
