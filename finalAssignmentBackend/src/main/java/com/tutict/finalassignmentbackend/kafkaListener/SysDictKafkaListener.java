package com.tutict.finalassignmentbackend.kafkaListener;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentbackend.entity.system.SysDict;
import com.tutict.finalassignmentbackend.service.admin.SysDictService;
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

    // 监听 Kafka 消息
    @KafkaListener(topics = "${kafka.topics.sys-dict.create:sys_dict_create}", groupId = "${kafka.groups.sys-dict:sysDictGroup}", concurrency = "3")
    public void onSysDictCreate(@Header(value = KafkaHeaders.RECEIVED_KEY, required = false) byte[] rawKey,
                                @Payload String message,
                                      Acknowledgment ack) {
        log.log(Level.INFO, "Received Kafka message for SysDict create (payload omitted)");
        processMessage(asKey(rawKey), message, "create");
        ack.acknowledge();
    }

    // 监听 Kafka 消息
    @KafkaListener(topics = "${kafka.topics.sys-dict.update:sys_dict_update}", groupId = "${kafka.groups.sys-dict:sysDictGroup}", concurrency = "3")
    public void onSysDictUpdate(@Header(value = KafkaHeaders.RECEIVED_KEY, required = false) byte[] rawKey,
                                @Payload String message,
                                      Acknowledgment ack) {
        log.log(Level.INFO, "Received Kafka message for SysDict update (payload omitted)");
        processMessage(asKey(rawKey), message, "update");
        ack.acknowledge();
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
    private SysDict deserializeMessage(String message) {
        try {
            return objectMapper.readValue(message, SysDict.class);
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
