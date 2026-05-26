package com.tutict.finalassignmentbackend.kafkaListener;

import com.tutict.finalassignmentbackend.common.idempotency.IdempotentKafkaMessageProcessor;
import com.tutict.finalassignmentbackend.entity.audit.AuditLoginLog;
import com.tutict.finalassignmentbackend.service.audit.AuditLoginLogService;
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
public class AuditLoginLogKafkaListener {

    private static final Logger log = Logger.getLogger(AuditLoginLogKafkaListener.class.getName());

    private final AuditLoginLogService auditLoginLogService;
    private final IdempotentKafkaMessageProcessor messageProcessor;

    @Autowired
    public AuditLoginLogKafkaListener(AuditLoginLogService auditLoginLogService,
                                      IdempotentKafkaMessageProcessor messageProcessor) {
        this.auditLoginLogService = auditLoginLogService;
        this.messageProcessor = messageProcessor;
    }

    @KafkaListener(topics = "${kafka.topics.audit-login-log.create:audit_login_log_create}", groupId = "${kafka.groups.audit-login-log:auditLoginLogGroup}", concurrency = "3")
    public void onAuditLoginLogCreateReceived(@Header(value = KafkaHeaders.RECEIVED_KEY, required = false) byte[] rawKey,
                                              @Payload String message,
                                              Acknowledgment ack) {
        log.log(Level.INFO, "Received Kafka message for create (payload omitted)");
        processMessage(asKey(rawKey), message, "create", ack);
    }

    @KafkaListener(topics = "${kafka.topics.audit-login-log.update:audit_login_log_update}", groupId = "${kafka.groups.audit-login-log:auditLoginLogGroup}", concurrency = "3")
    public void onAuditLoginLogUpdateReceived(@Header(value = KafkaHeaders.RECEIVED_KEY, required = false) byte[] rawKey,
                                              @Payload String message,
                                              Acknowledgment ack) {
        log.log(Level.INFO, "Received Kafka message for update (payload omitted)");
        processMessage(asKey(rawKey), message, "update", ack);
    }

    private void processMessage(String idempotencyKey, String message, String action, Acknowledgment ack) {
        if (isBlank(idempotencyKey)) {
            log.warning("Received AuditLoginLog event without idempotency key, skipping");
            acknowledge(ack);
            return;
        }
        messageProcessor.process(
                idempotencyKey,
                message,
                ack,
                "AuditLoginLog",
                action,
                auditLoginLogService::shouldSkipProcessing,
                payload -> processPayload(payload, action),
                (key, result) -> {
                    if (result != null && result.getLogId() != null) {
                        auditLoginLogService.markHistorySuccess(key, result.getLogId());
                    }
                },
                (key, ex) -> auditLoginLogService.markHistoryFailure(key, ex.getMessage())
        );
    }

    private AuditLoginLog processPayload(String message, String action) {
        AuditLoginLog payload = messageProcessor.deserialize(message, AuditLoginLog.class);
        if ("create".equalsIgnoreCase(action)) {
            payload.setLogId(null);
            return auditLoginLogService.createAuditLoginLog(payload);
        }
        if ("update".equalsIgnoreCase(action)) {
            return auditLoginLogService.updateAuditLoginLog(payload);
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
