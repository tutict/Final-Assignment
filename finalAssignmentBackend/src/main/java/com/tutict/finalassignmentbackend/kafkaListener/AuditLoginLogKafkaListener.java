package com.tutict.finalassignmentbackend.kafkaListener;

import com.fasterxml.jackson.databind.ObjectMapper;
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
// Kafka 监听器，处理消息
public class AuditLoginLogKafkaListener {

    private static final Logger log = Logger.getLogger(AuditLoginLogKafkaListener.class.getName());

    private final AuditLoginLogService auditLoginLogService;
    private final ObjectMapper objectMapper;

    // 构造器注入依赖
    @Autowired
    public AuditLoginLogKafkaListener(AuditLoginLogService auditLoginLogService,
                                      ObjectMapper objectMapper) {
        this.auditLoginLogService = auditLoginLogService;
        this.objectMapper = objectMapper;
    }

    // 监听 Kafka 消息
    @KafkaListener(topics = "${kafka.topics.audit-login-log.create:audit_login_log_create}", groupId = "${kafka.groups.audit-login-log:auditLoginLogGroup}", concurrency = "3")
    public void onAuditLoginLogCreateReceived(@Header(value = KafkaHeaders.RECEIVED_KEY, required = false) byte[] rawKey,
                                              @Payload String message,
                                      Acknowledgment ack) {
        log.log(Level.INFO, "Received Kafka message for create (payload omitted)");
        processMessage(asKey(rawKey), message, "create");
        ack.acknowledge();
    }

    // 监听 Kafka 消息
    @KafkaListener(topics = "${kafka.topics.audit-login-log.update:audit_login_log_update}", groupId = "${kafka.groups.audit-login-log:auditLoginLogGroup}", concurrency = "3")
    public void onAuditLoginLogUpdateReceived(@Header(value = KafkaHeaders.RECEIVED_KEY, required = false) byte[] rawKey,
                                              @Payload String message,
                                      Acknowledgment ack) {
        log.log(Level.INFO, "Received Kafka message for update (payload omitted)");
        processMessage(asKey(rawKey), message, "update");
        ack.acknowledge();
    }

    // 统一处理消息并执行业务逻辑
    private void processMessage(String idempotencyKey, String message, String action) {
        if (isBlank(idempotencyKey)) {
            log.warning("Received AuditLoginLog event without idempotency key, skipping");
            return;
        }
        try {
            AuditLoginLog payload = deserializeMessage(message);
            if (payload == null) {
                log.warning("Received AuditLoginLog event with empty payload, skipping");
                return;
            }
            if (auditLoginLogService.shouldSkipProcessing(idempotencyKey)) {
                log.log(Level.INFO, "Skipping duplicate AuditLoginLog event (key={0}, action={1})",
                        new Object[]{idempotencyKey, action});
                return;
            }
            AuditLoginLog result;
            if ("create".equalsIgnoreCase(action)) {
                payload.setLogId(null);
                result = auditLoginLogService.createAuditLoginLog(payload);
            } else if ("update".equalsIgnoreCase(action)) {
                result = auditLoginLogService.updateAuditLoginLog(payload);
            } else {
                log.log(Level.WARNING, "Unsupported action: {0}", action);
                return;
            }
            auditLoginLogService.markHistorySuccess(idempotencyKey, result.getLogId());
            log.info(String.format("AuditLoginLog %s action processed successfully (key=%s)", action, idempotencyKey));
        } catch (Exception e) {
            auditLoginLogService.markHistoryFailure(idempotencyKey, e.getMessage());
            log.log(Level.SEVERE,
                    String.format("Error processing %s AuditLoginLog message (key=%s, payload omitted)", action, idempotencyKey),
                    e);
            throw e;
        }
    }
    private AuditLoginLog deserializeMessage(String message) {
        try {
            return objectMapper.readValue(message, AuditLoginLog.class);
        } catch (Exception e) {
            log.log(Level.SEVERE, "Failed to deserialize Kafka message (payload omitted)", e);
            throw new IllegalArgumentException("Failed to deserialize Kafka message", e);
        }
    }
    private String asKey(byte[] rawKey) {
        return rawKey == null ? null : new String(rawKey);
    }

    // 判空
    private boolean isBlank(String value) {
        return value == null || value.trim().isEmpty();
    }
}
