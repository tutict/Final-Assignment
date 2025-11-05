package com.tutict.finalassignmentbackend.kafkaListener;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentbackend.entity.SysDict;
import com.tutict.finalassignmentbackend.service.SysDictService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.kafka.support.KafkaHeaders;
import org.springframework.messaging.handler.annotation.Header;
import org.springframework.messaging.handler.annotation.Payload;
import org.springframework.stereotype.Service;

import java.util.logging.Level;
import java.util.logging.Logger;

@Service
public class SysDictKafkaListener {

    private static final Logger log = Logger.getLogger(SysDictKafkaListener.class.getName());

    private final SysDictService sysDictService;
    private final ObjectMapper objectMapper;

    @Autowired
    public SysDictKafkaListener(SysDictService sysDictService,
                                ObjectMapper objectMapper) {
        this.sysDictService = sysDictService;
        this.objectMapper = objectMapper;
    }

    @KafkaListener(topics = "sys_dict_create", groupId = "sysDictGroup", concurrency = "3")
    public void onSysDictCreate(@Header(value = KafkaHeaders.RECEIVED_KEY, required = false) byte[] rawKey,
                                @Payload String message) {
        log.log(Level.INFO, "Received Kafka message for SysDict create: {0}", message);
        Thread.ofVirtual().start(() -> processMessage(asKey(rawKey), message, "create"));
    }

    @KafkaListener(topics = "sys_dict_update", groupId = "sysDictGroup", concurrency = "3")
    public void onSysDictUpdate(@Header(value = KafkaHeaders.RECEIVED_KEY, required = false) byte[] rawKey,
                                @Payload String message) {
        log.log(Level.INFO, "Received Kafka message for SysDict update: {0}", message);
        Thread.ofVirtual().start(() -> processMessage(asKey(rawKey), message, "update"));
    }

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
            log.log(Level.SEVERE, "Failed to deserialize SysDict message: {0}", message);
            return null;
        }
    }

    private String asKey(byte[] rawKey) {
        return rawKey == null ? null : new String(rawKey);
    }

    private boolean isBlank(String value) {
        return value == null || value.trim().isEmpty();
    }
}
