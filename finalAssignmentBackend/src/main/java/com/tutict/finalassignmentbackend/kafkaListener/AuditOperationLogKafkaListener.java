package com.tutict.finalassignmentbackend.kafkaListener;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentbackend.entity.AuditOperationLog;
import com.tutict.finalassignmentbackend.service.AuditOperationLogService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.kafka.support.KafkaHeaders;
import org.springframework.messaging.handler.annotation.Header;
import org.springframework.messaging.handler.annotation.Payload;
import org.springframework.stereotype.Service;

import java.util.logging.Level;
import java.util.logging.Logger;

@Service
public class AuditOperationLogKafkaListener {

    private static final Logger log = Logger.getLogger(AuditOperationLogKafkaListener.class.getName());

    private final AuditOperationLogService auditOperationLogService;
    private final ObjectMapper objectMapper;

    @Autowired
    public AuditOperationLogKafkaListener(AuditOperationLogService auditOperationLogService,
                                          ObjectMapper objectMapper) {
        this.auditOperationLogService = auditOperationLogService;
        this.objectMapper = objectMapper;
    }

    @KafkaListener(topics = "audit_operation_log_create", groupId = "auditOperationLogGroup", concurrency = "3")
    public void onAuditOperationLogCreateReceived(@Header(value = KafkaHeaders.RECEIVED_KEY, required = false) byte[] rawKey,
                                                  @Payload String message) {
        log.log(Level.INFO, "Received Kafka message for create: {0}", message);
        Thread.ofVirtual().start(() -> processMessage(asKey(rawKey), message, "create"));
    }

    @KafkaListener(topics = "audit_operation_log_update", groupId = "auditOperationLogGroup", concurrency = "3")
    public void onAuditOperationLogUpdateReceived(@Header(value = KafkaHeaders.RECEIVED_KEY, required = false) byte[] rawKey,
                                                  @Payload String message) {
        log.log(Level.INFO, "Received Kafka message for update: {0}", message);
        Thread.ofVirtual().start(() -> processMessage(asKey(rawKey), message, "update"));
    }

    private void processMessage(String idempotencyKey, String message, String action) {
        if (isBlank(idempotencyKey)) {
            log.warning("Received AuditOperationLog event without idempotency key, skipping");
            return;
        }
        try {
            AuditOperationLog payload = deserializeMessage(message);
            if (payload == null) {
                log.warning("Received AuditOperationLog event with empty payload, skipping");
                return;
            }
            if (auditOperationLogService.shouldSkipProcessing(idempotencyKey)) {
                log.log(Level.INFO, "Skipping duplicate AuditOperationLog event (key={0}, action={1})",
                        new Object[]{idempotencyKey, action});
                return;
            }
            AuditOperationLog result;
            if ("create".equalsIgnoreCase(action)) {
                payload.setLogId(null);
                result = auditOperationLogService.createAuditOperationLog(payload);
            } else if ("update".equalsIgnoreCase(action)) {
                result = auditOperationLogService.updateAuditOperationLog(payload);
            } else {
                log.log(Level.WARNING, "Unsupported action: {0}", action);
                return;
            }
            auditOperationLogService.markHistorySuccess(idempotencyKey, result.getLogId());
            log.info(String.format("AuditOperationLog %s action processed successfully (key=%s)", action, idempotencyKey));
        } catch (Exception e) {
            auditOperationLogService.markHistoryFailure(idempotencyKey, e.getMessage());
            log.log(Level.SEVERE,
                    String.format("Error processing %s AuditOperationLog message (key=%s): %s", action, idempotencyKey, message),
                    e);
            throw e;
        }
    }

    private AuditOperationLog deserializeMessage(String message) {
        try {
            return objectMapper.readValue(message, AuditOperationLog.class);
        } catch (Exception e) {
            log.log(Level.SEVERE, "Failed to deserialize message: {0}", message);
            return null;
        }
    }

    private String asKey(byte[] rawKey) {
        return rawKey == null ? null : new String(rawKey);
    }

    private boolean isBlank(String value) {
        return value == null || value.trim().isEmpty();
    }
}
