package com.tutict.finalassignmentbackend.kafkaListener;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentbackend.entity.SysBackupRestore;
import com.tutict.finalassignmentbackend.service.SysBackupRestoreService;
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
public class SysBackupRestoreKafkaListener {

    private static final Logger log = Logger.getLogger(SysBackupRestoreKafkaListener.class.getName());

    private final SysBackupRestoreService sysBackupRestoreService;
    private final ObjectMapper objectMapper;

    // 构造器注入依赖
    @Autowired
    public SysBackupRestoreKafkaListener(SysBackupRestoreService sysBackupRestoreService,
                                         ObjectMapper objectMapper) {
        this.sysBackupRestoreService = sysBackupRestoreService;
        this.objectMapper = objectMapper;
    }

    // 监听 Kafka 消息
    @KafkaListener(topics = "${kafka.topics.sys-backup-restore.create:sys_backup_restore_create}", groupId = "${kafka.groups.sys-backup-restore:sysBackupRestoreGroup}", concurrency = "3")
    public void onSysBackupRestoreCreateReceived(@Header(value = KafkaHeaders.RECEIVED_KEY, required = false) byte[] rawKey,
                                                 @Payload String message,
                                      Acknowledgment ack) {
        log.log(Level.INFO, "Received Kafka message for sys backup/restore create (payload omitted)");
        processMessage(asKey(rawKey), message, "create");
        ack.acknowledge();
    }

    // 监听 Kafka 消息
    @KafkaListener(topics = "${kafka.topics.sys-backup-restore.update:sys_backup_restore_update}", groupId = "${kafka.groups.sys-backup-restore:sysBackupRestoreGroup}", concurrency = "3")
    public void onSysBackupRestoreUpdateReceived(@Header(value = KafkaHeaders.RECEIVED_KEY, required = false) byte[] rawKey,
                                                 @Payload String message,
                                      Acknowledgment ack) {
        log.log(Level.INFO, "Received Kafka message for sys backup/restore update (payload omitted)");
        processMessage(asKey(rawKey), message, "update");
        ack.acknowledge();
    }

    // 统一处理消息并执行业务逻辑
    private void processMessage(String idempotencyKey, String message, String action) {
        if (isBlank(idempotencyKey)) {
            log.warning("Received SysBackupRestore event without idempotency key, skipping");
            return;
        }
        try {
            SysBackupRestore payload = deserializeMessage(message);
            if (payload == null) {
                log.warning("Received SysBackupRestore event with empty payload, skipping");
                return;
            }
            if (sysBackupRestoreService.shouldSkipProcessing(idempotencyKey)) {
                log.log(Level.INFO, "Skipping duplicate SysBackupRestore event (key={0}, action={1})",
                        new Object[]{idempotencyKey, action});
                return;
            }
            SysBackupRestore result;
            if ("create".equalsIgnoreCase(action)) {
                payload.setBackupId(null);
                result = sysBackupRestoreService.createSysBackupRestore(payload);
            } else if ("update".equalsIgnoreCase(action)) {
                result = sysBackupRestoreService.updateSysBackupRestore(payload);
            } else {
                log.log(Level.WARNING, "Unsupported SysBackupRestore action: {0}", action);
                return;
            }
            sysBackupRestoreService.markHistorySuccess(idempotencyKey, result.getBackupId());
            log.info(String.format("SysBackupRestore %s action processed successfully (key=%s)", action, idempotencyKey));
        } catch (Exception ex) {
            sysBackupRestoreService.markHistoryFailure(idempotencyKey, ex.getMessage());
            log.log(Level.SEVERE,
                    String.format("Error processing %s SysBackupRestore message (key=%s, payload omitted)", action, idempotencyKey),
                    ex);
            throw ex;
        }
    }
    private SysBackupRestore deserializeMessage(String message) {
        try {
            return objectMapper.readValue(message, SysBackupRestore.class);
        } catch (Exception ex) {
            log.log(Level.SEVERE, "Failed to deserialize Kafka message (payload omitted)", ex);
            throw new IllegalArgumentException("Failed to deserialize Kafka message", ex);
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
