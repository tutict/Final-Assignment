package com.tutict.finalassignmentbackend.kafkaListener;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentbackend.entity.OffenseRecord;
import com.tutict.finalassignmentbackend.offense.governance.OffenseGovernanceDecision;
import com.tutict.finalassignmentbackend.offense.governance.OffenseGovernanceLogFactory;
import com.tutict.finalassignmentbackend.offense.governance.SemanticIntentClassifier;
import com.tutict.finalassignmentbackend.offense.governance.StaleFullUpdateRejectedException;
import com.tutict.finalassignmentbackend.service.OffenseRecordService;
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
public class OffenseRecordKafkaListener {

    private static final Logger log = Logger.getLogger(OffenseRecordKafkaListener.class.getName());

    private final OffenseRecordService offenseRecordService;
    private final ObjectMapper objectMapper;
    private final SemanticIntentClassifier semanticIntentClassifier;

    // 构造器注入依赖
    @Autowired
    public OffenseRecordKafkaListener(OffenseRecordService offenseRecordService,
                                      ObjectMapper objectMapper) {
        this.offenseRecordService = offenseRecordService;
        this.objectMapper = objectMapper;
        this.semanticIntentClassifier = new SemanticIntentClassifier();
    }

    // 监听 Kafka 消息
    @KafkaListener(topics = "offense_record_create", groupId = "offenseRecordGroup", concurrency = "3")
    public void onOffenseRecordCreate(@Header(value = KafkaHeaders.RECEIVED_KEY, required = false) byte[] rawKey,
                                      @Payload String message,
                                      Acknowledgment ack) {
        log.log(Level.INFO, "Received Kafka message for OffenseRecord create (payload omitted)");
        processMessage(asKey(rawKey), message, "create");
        ack.acknowledge();
    }

    // 监听 Kafka 消息
    @KafkaListener(topics = "offense_record_update", groupId = "offenseRecordGroup", concurrency = "3")
    public void onOffenseRecordUpdate(@Header(value = KafkaHeaders.RECEIVED_KEY, required = false) byte[] rawKey,
                                      @Payload String message,
                                      Acknowledgment ack) {
        log.log(Level.INFO, "Received Kafka message for OffenseRecord update (payload omitted)");
        processMessage(asKey(rawKey), message, "update");
        ack.acknowledge();
    }

    // 统一处理消息并执行业务逻辑
    private void processMessage(String idempotencyKey, String message, String action) {
        if (isBlank(idempotencyKey)) {
            log.warning("Received OffenseRecord event without idempotency key, skipping");
            return;
        }
        OffenseRecord payload = deserializeMessage(message);
        if (payload == null) {
            log.warning("Received OffenseRecord event with empty payload, skipping");
            return;
        }
        try {
            boolean duplicate = offenseRecordService.shouldSkipProcessing(idempotencyKey);
            semanticIntentClassifier.classifyKafkaAction(action, duplicate);
            if (duplicate) {
                logGovernance(Level.INFO, OffenseGovernanceLogFactory.noOpSuppressed(
                                OffenseGovernanceDecision.Source.KAFKA,
                                payload.getOffenseId(),
                                "duplicate"
                        )
                        .withAttribute("kafkaKey", idempotencyKey)
                        .withAttribute("action", action));
                return;
            }

            OffenseRecord result;
            if ("create".equalsIgnoreCase(action)) {
                payload.setOffenseId(null);
                result = offenseRecordService.createOffenseRecord(payload);
            } else if ("update".equalsIgnoreCase(action)) {
                result = offenseRecordService.updateKafkaFullUpdate(payload);
            } else {
                log.log(Level.WARNING, "Unsupported OffenseRecord action: {0}", action);
                return;
            }
            offenseRecordService.markHistorySuccess(idempotencyKey, result.getOffenseId());
        } catch (StaleFullUpdateRejectedException ex) {
            logGovernance(Level.WARNING, ex.decision()
                    .withAttribute("kafkaKey", idempotencyKey)
                    .withAttribute("action", action));
        } catch (Exception ex) {
            offenseRecordService.markHistoryFailure(idempotencyKey, ex.getMessage());
            log.log(Level.SEVERE,
                    String.format("Error processing OffenseRecord event (key=%s, action=%s)", idempotencyKey, action),
                    ex);
            throw ex;
        }
    }
    private OffenseRecord deserializeMessage(String message) {
        try {
            return objectMapper.readValue(message, OffenseRecord.class);
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

    private void logGovernance(Level level, OffenseGovernanceDecision decision) {
        log.log(level, OffenseGovernanceLogFactory.format(decision));
    }
}
