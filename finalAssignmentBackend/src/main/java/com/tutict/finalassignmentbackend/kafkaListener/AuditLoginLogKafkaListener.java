package com.tutict.finalassignmentbackend.kafkaListener;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentbackend.entity.AuditLoginLog;
import com.tutict.finalassignmentbackend.mapper.AuditLoginLogMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.kafka.annotation.EnableKafka;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Service;

import java.util.logging.Level;
import java.util.logging.Logger;

@Service
@EnableKafka
public class AuditLoginLogKafkaListener {

    private static final Logger log = Logger.getLogger(AuditLoginLogKafkaListener.class.getName());

    private final AuditLoginLogMapper auditLoginLogMapper;
    private final ObjectMapper objectMapper;

    @Autowired
    public AuditLoginLogKafkaListener(AuditLoginLogMapper auditLoginLogMapper, ObjectMapper objectMapper) {
        this.auditLoginLogMapper = auditLoginLogMapper;
        this.objectMapper = objectMapper;
    }

    @KafkaListener(topics = "audit_login_log_create", groupId = "auditLoginLogGroup", concurrency = "3")
    public void onAuditLoginLogCreateReceived(String message) {
        log.log(Level.INFO, "Received Kafka message for create: {0}", message);
        Thread.ofVirtual().start(() -> processMessage(message, "create"));
    }

    @KafkaListener(topics = "audit_login_log_update", groupId = "auditLoginLogGroup", concurrency = "3")
    public void onAuditLoginLogUpdateReceived(String message) {
        log.log(Level.INFO, "Received Kafka message for update: {0}", message);
        Thread.ofVirtual().start(() -> processMessage(message, "update"));
    }

    private void processMessage(String message, String action) {
        try {
            AuditLoginLog entity = deserializeMessage(message);
            if ("create".equals(action)) {
                entity.setLogId(null);
                auditLoginLogMapper.insert(entity);
            } else if ("update".equals(action)) {
                auditLoginLogMapper.updateById(entity);
            } else {
                log.log(Level.WARNING, "Unsupported action: {0}", action);
                return;
            }
            log.info(String.format("AuditLoginLog %s action processed successfully: %s", action, entity));
        } catch (Exception e) {
            log.log(Level.SEVERE, String.format("Error processing %s AuditLoginLog message: %s", action, message), e);
            throw new RuntimeException(String.format("Failed to process %s AuditLoginLog message", action), e);
        }
    }

    private AuditLoginLog deserializeMessage(String message) {
        try {
            return objectMapper.readValue(message, AuditLoginLog.class);
        } catch (Exception e) {
            log.log(Level.SEVERE, "Failed to deserialize message: {0}", message);
            throw new RuntimeException("Failed to deserialize message", e);
        }
    }
}
