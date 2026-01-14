package com.tutict.finalassignmentcloud.user.kafkaListener;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentcloud.entity.SysRolePermission;
import com.tutict.finalassignmentcloud.user.service.SysRolePermissionService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.kafka.support.KafkaHeaders;
import org.springframework.messaging.handler.annotation.Header;
import org.springframework.messaging.handler.annotation.Payload;
import org.springframework.stereotype.Service;

import java.util.logging.Level;
import java.util.logging.Logger;

@Service
// Kafka 鐩戝惉鍣紝澶勭悊娑堟伅
public class SysRolePermissionKafkaListener {

    private static final Logger log = Logger.getLogger(SysRolePermissionKafkaListener.class.getName());

    private final SysRolePermissionService sysRolePermissionService;
    private final ObjectMapper objectMapper;

    // 鏋勯€犲櫒娉ㄥ叆渚濊禆
    @Autowired
    public SysRolePermissionKafkaListener(SysRolePermissionService sysRolePermissionService,
                                          ObjectMapper objectMapper) {
        this.sysRolePermissionService = sysRolePermissionService;
        this.objectMapper = objectMapper;
    }

    // 鐩戝惉 Kafka 娑堟伅
    @KafkaListener(topics = "sys_role_permission_create", groupId = "sysRolePermissionGroup", concurrency = "3")
    public void onSysRolePermissionCreateReceived(@Header(value = KafkaHeaders.RECEIVED_KEY, required = false) byte[] rawKey,
                                                  @Payload String message) {
        log.log(Level.INFO, "Received Kafka message for sys role permission create: {0}", message);
        // 使用虚拟线程异步处理，避免阻塞监听线程
        Thread.ofVirtual().start(() -> processMessage(asKey(rawKey), message, "create"));
    }

    // 鐩戝惉 Kafka 娑堟伅
    @KafkaListener(topics = "sys_role_permission_update", groupId = "sysRolePermissionGroup", concurrency = "3")
    public void onSysRolePermissionUpdateReceived(@Header(value = KafkaHeaders.RECEIVED_KEY, required = false) byte[] rawKey,
                                                  @Payload String message) {
        log.log(Level.INFO, "Received Kafka message for sys role permission update: {0}", message);
        // 使用虚拟线程异步处理，避免阻塞监听线程
        Thread.ofVirtual().start(() -> processMessage(asKey(rawKey), message, "update"));
    }

    // 缁熶竴澶勭悊娑堟伅骞舵墽琛屼笟鍔￠€昏緫
    private void processMessage(String idempotencyKey, String message, String action) {
        if (isBlank(idempotencyKey)) {
            log.warning("Received SysRolePermission event without idempotency key, skipping");
            return;
        }
        try {
            SysRolePermission payload = deserializeMessage(message);
            if (payload == null) {
                log.warning("Received SysRolePermission event with empty payload, skipping");
                return;
            }
            if (sysRolePermissionService.shouldSkipProcessing(idempotencyKey)) {
                log.log(Level.INFO, "Skipping duplicate SysRolePermission event (key={0}, action={1})",
                        new Object[]{idempotencyKey, action});
                return;
            }
            SysRolePermission result;
            if ("create".equalsIgnoreCase(action)) {
                payload.setId(null);
                result = sysRolePermissionService.createRelation(payload);
            } else if ("update".equalsIgnoreCase(action)) {
                result = sysRolePermissionService.updateRelation(payload);
            } else {
                log.log(Level.WARNING, "Unsupported SysRolePermission action: {0}", action);
                return;
            }
            sysRolePermissionService.markHistorySuccess(idempotencyKey, result.getId());
            log.info(String.format("SysRolePermission %s action processed successfully (key=%s)", action, idempotencyKey));
        } catch (Exception ex) {
            sysRolePermissionService.markHistoryFailure(idempotencyKey, ex.getMessage());
            log.log(Level.SEVERE,
                    String.format("Error processing %s SysRolePermission message (key=%s): %s", action, idempotencyKey, message),
                    ex);
            throw ex;
        }
    }

    // 反序列化消息体
    private SysRolePermission deserializeMessage(String message) {
        try {
            return objectMapper.readValue(message, SysRolePermission.class);
        } catch (Exception ex) {
            log.log(Level.SEVERE, "Failed to deserialize SysRolePermission message: {0}", message);
            return null;
        }
    }

    // 将 Kafka key 转为字符串
    private String asKey(byte[] rawKey) {
        return rawKey == null ? null : new String(rawKey);
    }

    // 鍒ょ┖
    private boolean isBlank(String value) {
        return value == null || value.trim().isEmpty();
    }
}

