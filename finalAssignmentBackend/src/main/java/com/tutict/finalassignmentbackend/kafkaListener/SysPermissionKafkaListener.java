package com.tutict.finalassignmentbackend.kafkaListener;

import com.tutict.finalassignmentbackend.common.idempotency.IdempotentKafkaMessageProcessor;
import com.tutict.finalassignmentbackend.entity.admin.SysPermission;
import com.tutict.finalassignmentbackend.service.admin.SysPermissionService;
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
public class SysPermissionKafkaListener {

    private static final Logger log = Logger.getLogger(SysPermissionKafkaListener.class.getName());

    private final SysPermissionService sysPermissionService;
    private final IdempotentKafkaMessageProcessor messageProcessor;

    @Autowired
    public SysPermissionKafkaListener(SysPermissionService sysPermissionService,
                                      IdempotentKafkaMessageProcessor messageProcessor) {
        this.sysPermissionService = sysPermissionService;
        this.messageProcessor = messageProcessor;
    }

    @KafkaListener(topics = "${kafka.topics.sys-permission.create:sys_permission_create}", groupId = "${kafka.groups.sys-permission:sysPermissionGroup}", concurrency = "3")
    public void onSysPermissionCreateReceived(@Header(value = KafkaHeaders.RECEIVED_KEY, required = false) byte[] rawKey,
                                              @Payload String message,
                                              Acknowledgment ack) {
        log.log(Level.INFO, "Received Kafka message for sys permission create (payload omitted)");
        processMessage(asKey(rawKey), message, "create", ack);
    }

    @KafkaListener(topics = "${kafka.topics.sys-permission.update:sys_permission_update}", groupId = "${kafka.groups.sys-permission:sysPermissionGroup}", concurrency = "3")
    public void onSysPermissionUpdateReceived(@Header(value = KafkaHeaders.RECEIVED_KEY, required = false) byte[] rawKey,
                                              @Payload String message,
                                              Acknowledgment ack) {
        log.log(Level.INFO, "Received Kafka message for sys permission update (payload omitted)");
        processMessage(asKey(rawKey), message, "update", ack);
    }

    private void processMessage(String idempotencyKey, String message, String action, Acknowledgment ack) {
        if (isBlank(idempotencyKey)) {
            log.warning("Received SysPermission event without idempotency key, skipping");
            acknowledge(ack);
            return;
        }
        messageProcessor.process(
                idempotencyKey,
                message,
                ack,
                "SysPermission",
                action,
                sysPermissionService::shouldSkipProcessing,
                payload -> processPayload(payload, action),
                (key, result) -> {
                    if (result != null && result.getPermissionId() != null) {
                        sysPermissionService.markHistorySuccess(key, result.getPermissionId());
                    }
                },
                (key, ex) -> sysPermissionService.markHistoryFailure(key, ex.getMessage())
        );
    }

    private SysPermission processPayload(String message, String action) {
        SysPermission payload = messageProcessor.deserialize(message, SysPermission.class);
        if ("create".equalsIgnoreCase(action)) {
            payload.setPermissionId(null);
            return sysPermissionService.createSysPermission(payload);
        }
        if ("update".equalsIgnoreCase(action)) {
            return sysPermissionService.updateSysPermission(payload);
        }
        log.log(Level.WARNING, "Unsupported SysPermission action: {0}", action);
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
