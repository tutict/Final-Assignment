package com.tutict.finalassignmentbackend.kafkaListener;

import com.tutict.finalassignmentbackend.common.idempotency.IdempotentKafkaMessageProcessor;
import com.tutict.finalassignmentbackend.entity.admin.SysRole;
import com.tutict.finalassignmentbackend.service.admin.SysRoleService;
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
public class SysRoleKafkaListener {

    private static final Logger log = Logger.getLogger(SysRoleKafkaListener.class.getName());

    private final SysRoleService sysRoleService;
    private final IdempotentKafkaMessageProcessor messageProcessor;

    @Autowired
    public SysRoleKafkaListener(SysRoleService sysRoleService,
                                IdempotentKafkaMessageProcessor messageProcessor) {
        this.sysRoleService = sysRoleService;
        this.messageProcessor = messageProcessor;
    }

    @KafkaListener(topics = "${kafka.topics.sys-role.create:sys_role_create}", groupId = "${kafka.groups.sys-role:sysRoleGroup}", concurrency = "3")
    public void onSysRoleCreateReceived(@Header(value = KafkaHeaders.RECEIVED_KEY, required = false) byte[] rawKey,
                                        @Payload String message,
                                        Acknowledgment ack) {
        log.log(Level.INFO, "Received Kafka message for sys role create (payload omitted)");
        processMessage(asKey(rawKey), message, "create", ack);
    }

    @KafkaListener(topics = "${kafka.topics.sys-role.update:sys_role_update}", groupId = "${kafka.groups.sys-role:sysRoleGroup}", concurrency = "3")
    public void onSysRoleUpdateReceived(@Header(value = KafkaHeaders.RECEIVED_KEY, required = false) byte[] rawKey,
                                        @Payload String message,
                                        Acknowledgment ack) {
        log.log(Level.INFO, "Received Kafka message for sys role update (payload omitted)");
        processMessage(asKey(rawKey), message, "update", ack);
    }

    private void processMessage(String idempotencyKey, String message, String action, Acknowledgment ack) {
        if (isBlank(idempotencyKey)) {
            log.warning("Received SysRole event without idempotency key, skipping");
            acknowledge(ack);
            return;
        }
        messageProcessor.process(
                idempotencyKey,
                message,
                ack,
                "SysRole",
                action,
                sysRoleService::shouldSkipProcessing,
                payload -> processPayload(payload, action),
                (key, result) -> {
                    if (result != null && result.getRoleId() != null) {
                        sysRoleService.markHistorySuccess(key, result.getRoleId());
                    }
                },
                (key, ex) -> sysRoleService.markHistoryFailure(key, ex.getMessage())
        );
    }

    private SysRole processPayload(String message, String action) {
        SysRole payload = messageProcessor.deserialize(message, SysRole.class);
        if ("create".equalsIgnoreCase(action)) {
            payload.setRoleId(null);
            return sysRoleService.createSysRole(payload);
        }
        if ("update".equalsIgnoreCase(action)) {
            return sysRoleService.updateSysRole(payload);
        }
        log.log(Level.WARNING, "Unsupported SysRole action: {0}", action);
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
