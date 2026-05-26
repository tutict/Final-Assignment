package com.tutict.finalassignmentbackend.kafkaListener;

import com.tutict.finalassignmentbackend.common.idempotency.IdempotentKafkaMessageProcessor;
import com.tutict.finalassignmentbackend.entity.audit.AuditOperationLog;
import com.tutict.finalassignmentbackend.service.audit.AuditOperationLogService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.kafka.support.Acknowledgment;
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
    private final IdempotentKafkaMessageProcessor messageProcessor;

    @Autowired
    public AuditOperationLogKafkaListener(AuditOperationLogService auditOperationLogService,
                                          IdempotentKafkaMessageProcessor messageProcessor) {
        this.auditOperationLogService = auditOperationLogService;
        this.messageProcessor = messageProcessor;
    }

    @KafkaListener(topics = "${kafka.topics.audit-operation-log.create:audit_operation_log_create}", groupId = "${kafka.groups.audit-operation-log:auditOperationLogGroup}", concurrency = "3")
    public void onAuditOperationLogCreateReceived(@Header(value = KafkaHeaders.RECEIVED_KEY, required = false) byte[] rawKey,
                                                  @Payload String message,
                                                  Acknowledgment ack) {
        log.log(Level.INFO, "Received Kafka message for create (payload omitted)");
        processMessage(asKey(rawKey), message, "create", ack);
    }

    @KafkaListener(topics = "${kafka.topics.audit-operation-log.update:audit_operation_log_update}", groupId = "${kafka.groups.audit-operation-log:auditOperationLogGroup}", concurrency = "3")
    public void onAuditOperationLogUpdateReceived(@Header(value = KafkaHeaders.RECEIVED_KEY, required = false) byte[] rawKey,
                                                  @Payload String message,
                                                  Acknowledgment ack) {
        log.log(Level.INFO, "Received Kafka message for update (payload omitted)");
        processMessage(asKey(rawKey), message, "update", ack);
    }

    private void processMessage(String idempotencyKey, String message, String action, Acknowledgment ack) {
        if (isBlank(idempotencyKey)) {
            log.warning("Received AuditOperationLog event without idempotency key, skipping");
            acknowledge(ack);
            return;
        }
        messageProcessor.process(
                idempotencyKey,
                message,
                ack,
                "AuditOperationLog",
                action,
                auditOperationLogService::shouldSkipProcessing,
                payload -> processPayload(payload, action),
                (key, result) -> {
                    if (result != null && result.getLogId() != null) {
                        auditOperationLogService.markHistorySuccess(key, result.getLogId());
                    }
                },
                (key, ex) -> auditOperationLogService.markHistoryFailure(key, ex.getMessage())
        );
    }

    private AuditOperationLog processPayload(String message, String action) {
        AuditOperationLog payload = messageProcessor.deserialize(message, AuditOperationLog.class);
        if ("create".equalsIgnoreCase(action)) {
            payload.setLogId(null);
            return auditOperationLogService.createAuditOperationLog(payload);
        }
        if ("update".equalsIgnoreCase(action)) {
            return auditOperationLogService.updateAuditOperationLog(payload);
        }
        log.log(Level.WARNING, "Unsupported action: {0}", action);
        return null;
    }

    private String asKey(byte[] rawKey) {
        return rawKey == null ? null : new String(rawKey);
    }

    private boolean isBlank(String value) {
        return value == null || value.trim().isEmpty();
    }

    private void acknowledge(Acknowledgment acknowledgment) {
        if (acknowledgment != null) {
            acknowledgment.acknowledge();
        }
    }
}
