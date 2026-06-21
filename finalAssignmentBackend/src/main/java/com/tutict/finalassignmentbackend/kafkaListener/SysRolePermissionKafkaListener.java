package com.tutict.finalassignmentbackend.kafkaListener;

import com.tutict.finalassignmentbackend.common.idempotency.IdempotentKafkaMessageProcessor;
import com.tutict.finalassignmentbackend.entity.admin.SysRolePermission;
import com.tutict.finalassignmentbackend.service.admin.SysRolePermissionService;
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
public class SysRolePermissionKafkaListener {

    private static final Logger log = Logger.getLogger(SysRolePermissionKafkaListener.class.getName());

    private final SysRolePermissionService sysRolePermissionService;
    private final IdempotentKafkaMessageProcessor messageProcessor;

    @Autowired
    public SysRolePermissionKafkaListener(SysRolePermissionService sysRolePermissionService,
                                          IdempotentKafkaMessageProcessor messageProcessor) {
        this.sysRolePermissionService = sysRolePermissionService;
        this.messageProcessor = messageProcessor;
    }

    @KafkaListener(topics = "${kafka.topics.sys-role-permission.create:sys_role_permission_create}", groupId = "${kafka.groups.sys-role-permission:sysRolePermissionGroup}", concurrency = "3")
    public void onSysRolePermissionCreateReceived(@Header(value = KafkaHeaders.RECEIVED_KEY, required = false) byte[] rawKey,
                                                  @Payload String message,
                                                  Acknowledgment ack) {
        log.log(Level.INFO, "Received Kafka message for sys role permission create (payload omitted)");
        processMessage(asKey(rawKey), message, "create", ack);
    }

    @KafkaListener(topics = "${kafka.topics.sys-role-permission.update:sys_role_permission_update}", groupId = "${kafka.groups.sys-role-permission:sysRolePermissionGroup}", concurrency = "3")
    public void onSysRolePermissionUpdateReceived(@Header(value = KafkaHeaders.RECEIVED_KEY, required = false) byte[] rawKey,
                                                  @Payload String message,
                                                  Acknowledgment ack) {
        log.log(Level.INFO, "Received Kafka message for sys role permission update (payload omitted)");
        processMessage(asKey(rawKey), message, "update", ack);
    }

    private void processMessage(String idempotencyKey, String message, String action, Acknowledgment ack) {
        if (isBlank(idempotencyKey)) {
            log.warning("Received SysRolePermission event without idempotency key, skipping");
            acknowledge(ack);
            return;
        }
        messageProcessor.process(
                idempotencyKey,
                message,
                ack,
                "SysRolePermission",
                action,
                sysRolePermissionService::shouldSkipProcessing,
                payload -> processPayload(payload, action),
                (key, result) -> {
                    if (result != null && result.getId() != null) {
                        sysRolePermissionService.markHistorySuccess(key, result.getId());
                    }
                },
                (key, ex) -> sysRolePermissionService.markHistoryFailure(key, ex.getMessage())
        );
    }

    private SysRolePermission processPayload(String message, String action) {
        SysRolePermission payload = messageProcessor.deserialize(message, SysRolePermission.class);
        if ("create".equalsIgnoreCase(action)) {
            payload.setId(null);
            return sysRolePermissionService.createRelation(payload);
        }
        if ("update".equalsIgnoreCase(action)) {
            return sysRolePermissionService.updateRelation(payload);
        }
        log.log(Level.WARNING, "Unsupported SysRolePermission action: {0}", action);
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
