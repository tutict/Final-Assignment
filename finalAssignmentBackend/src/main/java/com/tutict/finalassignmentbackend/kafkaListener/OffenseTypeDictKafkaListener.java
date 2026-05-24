package com.tutict.finalassignmentbackend.kafkaListener;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentbackend.entity.offense.OffenseTypeDict;
import com.tutict.finalassignmentbackend.service.offense.OffenseTypeDictService;
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
public class OffenseTypeDictKafkaListener {

    private static final Logger log = Logger.getLogger(OffenseTypeDictKafkaListener.class.getName());

    private final OffenseTypeDictService offenseTypeDictService;
    private final ObjectMapper objectMapper;

    // 构造器注入依赖
    @Autowired
    public OffenseTypeDictKafkaListener(OffenseTypeDictService offenseTypeDictService,
                                        ObjectMapper objectMapper) {
        this.offenseTypeDictService = offenseTypeDictService;
        this.objectMapper = objectMapper;
    }

    // 监听 Kafka 消息
    @KafkaListener(topics = "${kafka.topics.offense-type-dict.create:offense_type_dict_create}", groupId = "${kafka.groups.offense-type-dict:offenseTypeDictGroup}", concurrency = "3")
    public void onOffenseTypeDictCreate(@Header(value = KafkaHeaders.RECEIVED_KEY, required = false) byte[] rawKey,
                                        @Payload String message,
                                      Acknowledgment ack) {
        log.log(Level.INFO, "Received Kafka message for OffenseTypeDict create (payload omitted)");
        processMessage(asKey(rawKey), message, "create");
        ack.acknowledge();
    }

    // 监听 Kafka 消息
    @KafkaListener(topics = "${kafka.topics.offense-type-dict.update:offense_type_dict_update}", groupId = "${kafka.groups.offense-type-dict:offenseTypeDictGroup}", concurrency = "3")
    public void onOffenseTypeDictUpdate(@Header(value = KafkaHeaders.RECEIVED_KEY, required = false) byte[] rawKey,
                                        @Payload String message,
                                      Acknowledgment ack) {
        log.log(Level.INFO, "Received Kafka message for OffenseTypeDict update (payload omitted)");
        processMessage(asKey(rawKey), message, "update");
        ack.acknowledge();
    }

    // 统一处理消息并执行业务逻辑
    private void processMessage(String idempotencyKey, String message, String action) {
        if (isBlank(idempotencyKey)) {
            log.warning("Received OffenseTypeDict event without idempotency key, skipping");
            return;
        }
        OffenseTypeDict payload = deserializeMessage(message);
        if (payload == null) {
            log.warning("Received OffenseTypeDict event with empty payload, skipping");
            return;
        }
        try {
            if (offenseTypeDictService.shouldSkipProcessing(idempotencyKey)) {
                log.log(Level.INFO, "Skipping duplicate OffenseTypeDict event (key={0}, action={1})",
                        new Object[]{idempotencyKey, action});
                return;
            }
            OffenseTypeDict result;
            if ("create".equalsIgnoreCase(action)) {
                payload.setTypeId(null);
                result = offenseTypeDictService.createDict(payload);
            } else if ("update".equalsIgnoreCase(action)) {
                result = offenseTypeDictService.updateDict(payload);
            } else {
                log.log(Level.WARNING, "Unsupported OffenseTypeDict action: {0}", action);
                return;
            }
            offenseTypeDictService.markHistorySuccess(idempotencyKey, result.getTypeId());
        } catch (Exception ex) {
            offenseTypeDictService.markHistoryFailure(idempotencyKey, ex.getMessage());
            log.log(Level.SEVERE,
                    String.format("Error processing OffenseTypeDict event (key=%s, action=%s)", idempotencyKey, action),
                    ex);
            throw ex;
        }
    }
    private OffenseTypeDict deserializeMessage(String message) {
        try {
            return objectMapper.readValue(message, OffenseTypeDict.class);
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
