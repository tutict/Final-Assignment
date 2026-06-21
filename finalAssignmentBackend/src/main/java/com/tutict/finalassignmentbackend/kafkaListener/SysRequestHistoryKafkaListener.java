package com.tutict.finalassignmentbackend.kafkaListener;

import com.tutict.finalassignmentbackend.common.idempotency.IdempotentKafkaMessageProcessor;
import com.tutict.finalassignmentbackend.entity.system.SysRequestHistory;
import com.tutict.finalassignmentbackend.service.system.SysRequestHistoryService;
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
public class SysRequestHistoryKafkaListener {

    private static final Logger log = Logger.getLogger(SysRequestHistoryKafkaListener.class.getName());

    private final SysRequestHistoryService sysRequestHistoryService;
    private final IdempotentKafkaMessageProcessor messageProcessor;

    @Autowired
    public SysRequestHistoryKafkaListener(SysRequestHistoryService sysRequestHistoryService,
                                          IdempotentKafkaMessageProcessor messageProcessor) {
        this.sysRequestHistoryService = sysRequestHistoryService;
        this.messageProcessor = messageProcessor;
    }

    @KafkaListener(topics = "${kafka.topics.sys-request-history.create:sys_request_history_create}", groupId = "${kafka.groups.sys-request-history:sysRequestHistoryGroup}", concurrency = "3")
    public void onSysRequestHistoryCreateReceived(@Header(value = KafkaHeaders.RECEIVED_KEY, required = false) byte[] rawKey,
                                                  @Payload String message,
                                                  Acknowledgment ack) {
        log.log(Level.INFO, "Received Kafka message for sys request history create (payload omitted)");
        processMessage(asKey(rawKey), message, "create", ack);
    }

    @KafkaListener(topics = "${kafka.topics.sys-request-history.update:sys_request_history_update}", groupId = "${kafka.groups.sys-request-history:sysRequestHistoryGroup}", concurrency = "3")
    public void onSysRequestHistoryUpdateReceived(@Header(value = KafkaHeaders.RECEIVED_KEY, required = false) byte[] rawKey,
                                                  @Payload String message,
                                                  Acknowledgment ack) {
        log.log(Level.INFO, "Received Kafka message for sys request history update (payload omitted)");
        processMessage(asKey(rawKey), message, "update", ack);
    }

    private void processMessage(String idempotencyKey, String message, String action, Acknowledgment ack) {
        if (isBlank(idempotencyKey)) {
            log.warning("Received SysRequestHistory event without idempotency key, skipping");
            acknowledge(ack);
            return;
        }
        messageProcessor.process(
                idempotencyKey,
                message,
                ack,
                "SysRequestHistory",
                action,
                sysRequestHistoryService::shouldSkipProcessing,
                payload -> processPayload(payload, action),
                (key, result) -> {
                    if (result != null && result.getId() != null) {
                        sysRequestHistoryService.markHistorySuccess(key, result.getId());
                    }
                },
                (key, ex) -> sysRequestHistoryService.markHistoryFailure(key, ex.getMessage())
        );
    }

    private SysRequestHistory processPayload(String message, String action) {
        SysRequestHistory payload = messageProcessor.deserialize(message, SysRequestHistory.class);
        if ("create".equalsIgnoreCase(action)) {
            payload.setId(null);
            return sysRequestHistoryService.createSysRequestHistory(payload);
        }
        if ("update".equalsIgnoreCase(action)) {
            return sysRequestHistoryService.updateSysRequestHistory(payload);
        }
        log.log(Level.WARNING, "Unsupported SysRequestHistory action: {0}", action);
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
