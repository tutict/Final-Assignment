package com.tutict.finalassignmentbackend.kafkaListener;

import com.tutict.finalassignmentbackend.common.idempotency.IdempotentKafkaMessageProcessor;
import com.tutict.finalassignmentbackend.entity.system.SysBackupRestore;
import com.tutict.finalassignmentbackend.service.admin.SysBackupRestoreService;
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
public class SysBackupRestoreKafkaListener {

    private static final Logger log = Logger.getLogger(SysBackupRestoreKafkaListener.class.getName());

    private final SysBackupRestoreService sysBackupRestoreService;
    private final IdempotentKafkaMessageProcessor messageProcessor;

    @Autowired
    public SysBackupRestoreKafkaListener(SysBackupRestoreService sysBackupRestoreService,
                                         IdempotentKafkaMessageProcessor messageProcessor) {
        this.sysBackupRestoreService = sysBackupRestoreService;
        this.messageProcessor = messageProcessor;
    }

    @KafkaListener(topics = "${kafka.topics.sys-backup-restore.create:sys_backup_restore_create}", groupId = "${kafka.groups.sys-backup-restore:sysBackupRestoreGroup}", concurrency = "3")
    public void onSysBackupRestoreCreateReceived(@Header(value = KafkaHeaders.RECEIVED_KEY, required = false) byte[] rawKey,
                                                 @Payload String message,
                                                 Acknowledgment ack) {
        log.log(Level.INFO, "Received Kafka message for sys backup/restore create (payload omitted)");
        processMessage(asKey(rawKey), message, "create", ack);
    }

    @KafkaListener(topics = "${kafka.topics.sys-backup-restore.update:sys_backup_restore_update}", groupId = "${kafka.groups.sys-backup-restore:sysBackupRestoreGroup}", concurrency = "3")
    public void onSysBackupRestoreUpdateReceived(@Header(value = KafkaHeaders.RECEIVED_KEY, required = false) byte[] rawKey,
                                                 @Payload String message,
                                                 Acknowledgment ack) {
        log.log(Level.INFO, "Received Kafka message for sys backup/restore update (payload omitted)");
        processMessage(asKey(rawKey), message, "update", ack);
    }

    private void processMessage(String idempotencyKey, String message, String action, Acknowledgment ack) {
        if (isBlank(idempotencyKey)) {
            log.warning("Received SysBackupRestore event without idempotency key, skipping");
            acknowledge(ack);
            return;
        }
        messageProcessor.process(
                idempotencyKey,
                message,
                ack,
                "SysBackupRestore",
                action,
                sysBackupRestoreService::shouldSkipProcessing,
                payload -> processPayload(payload, action),
                (key, result) -> {
                    if (result != null && result.getBackupId() != null) {
                        sysBackupRestoreService.markHistorySuccess(key, result.getBackupId());
                    }
                },
                (key, ex) -> sysBackupRestoreService.markHistoryFailure(key, ex.getMessage())
        );
    }

    private SysBackupRestore processPayload(String message, String action) {
        SysBackupRestore payload = messageProcessor.deserialize(message, SysBackupRestore.class);
        if ("create".equalsIgnoreCase(action)) {
            payload.setBackupId(null);
            return sysBackupRestoreService.createSysBackupRestore(payload);
        }
        if ("update".equalsIgnoreCase(action)) {
            return sysBackupRestoreService.updateSysBackupRestore(payload);
        }
        log.log(Level.WARNING, "Unsupported SysBackupRestore action: {0}", action);
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
