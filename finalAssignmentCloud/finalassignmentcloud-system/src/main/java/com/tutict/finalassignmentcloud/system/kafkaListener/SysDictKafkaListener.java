package com.tutict.finalassignmentcloud.system.kafkaListener;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentcloud.entity.SysDict;
import com.tutict.finalassignmentcloud.system.service.SysDictService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.kafka.support.KafkaHeaders;
import org.springframework.messaging.handler.annotation.Header;
import org.springframework.messaging.handler.annotation.Payload;
import org.springframework.stereotype.Service;

import java.util.logging.Level;
import java.util.logging.Logger;

@Service
// Kafka 监听器，处理消息
public class SysDictKafkaListener {

    private static final Logger log = Logger.getLogger(SysDictKafkaListener.class.getName());

    private final SysDictService sysDictService;
    private final ObjectMapper objectMapper;

    // 构造器注入依赖
    @Autowired
    public SysDictKafkaListener(SysDictService sysDictService,
                                ObjectMapper objectMapper) {
        this.sysDictService = sysDictService;
        this.objectMapper = objectMapper;
    }

    // 监听 Kafka 消息（创建）
    @KafkaListener(topics = "sys_dict_create", groupId = "sysDictGroup", concurrency = "3")
    public void onSysDictCreate(
            @Header(value = KafkaHeaders.RECEIVED_KEY, required = false) byte[] rawKey,
            @Payload String message) {
        log.log(Level.INFO, "Received Kafka message for SysDict create: {0}", message);
        // 使用虚拟线程异步处理，避免阻塞监听线程
        Thread.ofVirtual().start(() -> processMessage(asKey(rawKey), message, "create"));
    }

    // 监听 Kafka 消息（更新）
    @KafkaListener(topics = "sys_dict_update", groupId = "sysDictGroup", concurrency = "3")
    public void onSysDictUpdate(
            @Header(value = KafkaHeaders.RECEIVED_KEY, required = false) byte[] rawKey,
            @Payload String message) {
        log.log(Level.INFO, "Received Kafka message for SysDict update: {0}", message);
        // 使用虚拟线程异步处理，避免阻塞监听线程
        Thread.ofVirtual().start(() -> processMessage(asKey(rawKey), message, "update"));
    }

    // 统一处理消息并执行业务逻辑
    private void processMessage(String idempotencyKey, String message, String action) {
        if (isBlank(idempotencyKey)) {
            log.warning("Received SysDict event without idempotency key, skipping");
            return;
        }
        SysDict payload = deserializeMessage(message);
        if (payload == null) {
            log.warning("Received SysDict event with empty payload, skipping");
            return;
        }
        try {
            if (sysDictService.shouldSkipProcessing(idempotencyKey)) {
                log.log(Level.INFO, "Skipping duplicate SysDict event (key={0}, action={1})",
                        new Object[]{idempotencyKey, action});
                return;
            }
            SysDict result;
            if ("create".equalsIgnoreCase(action)) {
                payload.setDictId(null);
                result = sysDictService.createSysDict(payload);
            } else if ("update".equalsIgnoreCase(action)) {
                result = sysDictService.updateSysDict(payload);
            } else {
                log.log(Level.WARNING, "Unsupported SysDict action: {0}", action);
                return;
            }
            sysDictService.markHistorySuccess(idempotencyKey, result.getDictId());
        } catch (Exception ex) {
            sysDictService.markHistoryFailure(idempotencyKey, ex.getMessage());
            log.log(Level.SEVERE,
                    String.format("Error processing SysDict event (key=%s, action=%s)", idempotencyKey, action),
                    ex);
            throw ex;
        }
    }

    // 反序列化消息体
    private SysDict deserializeMessage(String message) {
        try {
            return objectMapper.readValue(message, SysDict.class);
        } catch (Exception ex) {
            log.log(Level.SEVERE, "Failed to deserialize SysDict message: {0}", message);
            return null;
        }
    }

    // 将 Kafka key 转为字符串
    private String asKey(byte[] rawKey) {
        return rawKey == null ? null : new String(rawKey);
    }

    // 判空
    private boolean isBlank(String value) {
        return value == null || value.trim().isEmpty();
    }
}