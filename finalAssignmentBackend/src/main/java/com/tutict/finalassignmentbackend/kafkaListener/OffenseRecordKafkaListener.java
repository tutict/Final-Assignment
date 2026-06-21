package com.tutict.finalassignmentbackend.kafkaListener;

import com.tutict.finalassignmentbackend.common.idempotency.IdempotentKafkaMessageProcessor;
import com.tutict.finalassignmentbackend.entity.offense.OffenseRecord;
import com.tutict.finalassignmentbackend.offense.governance.OffenseGovernanceDecision;
import com.tutict.finalassignmentbackend.offense.governance.OffenseGovernanceLogFactory;
import com.tutict.finalassignmentbackend.offense.governance.SemanticIntentClassifier;
import com.tutict.finalassignmentbackend.offense.governance.StaleFullUpdateRejectedException;
import com.tutict.finalassignmentbackend.service.offense.OffenseRecordService;
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
public class OffenseRecordKafkaListener {

    private static final Logger log = Logger.getLogger(OffenseRecordKafkaListener.class.getName());

    private final OffenseRecordService offenseRecordService;
    private final IdempotentKafkaMessageProcessor messageProcessor;
    private final SemanticIntentClassifier semanticIntentClassifier;

    @Autowired
    public OffenseRecordKafkaListener(OffenseRecordService offenseRecordService,
                                      IdempotentKafkaMessageProcessor messageProcessor) {
        this.offenseRecordService = offenseRecordService;
        this.messageProcessor = messageProcessor;
        this.semanticIntentClassifier = new SemanticIntentClassifier();
    }

    @KafkaListener(topics = "${kafka.topics.offense.create:offense_record_create}", groupId = "${kafka.groups.offense:offenseRecordGroup}", concurrency = "3")
    public void onOffenseRecordCreate(@Header(value = KafkaHeaders.RECEIVED_KEY, required = false) byte[] rawKey,
                                      @Payload String message,
                                      Acknowledgment ack) {
        log.log(Level.INFO, "Received Kafka message for OffenseRecord create (payload omitted)");
        processMessage(asKey(rawKey), message, "create", ack);
    }

    @KafkaListener(topics = "${kafka.topics.offense.update:offense_record_update}", groupId = "${kafka.groups.offense:offenseRecordGroup}", concurrency = "3")
    public void onOffenseRecordUpdate(@Header(value = KafkaHeaders.RECEIVED_KEY, required = false) byte[] rawKey,
                                      @Payload String message,
                                      Acknowledgment ack) {
        log.log(Level.INFO, "Received Kafka message for OffenseRecord update (payload omitted)");
        processMessage(asKey(rawKey), message, "update", ack);
    }

    private void processMessage(String idempotencyKey, String message, String action, Acknowledgment ack) {
        if (isBlank(idempotencyKey)) {
            log.warning("Received OffenseRecord event without idempotency key, skipping");
            acknowledge(ack);
            return;
        }

        OffenseRecord payload = messageProcessor.deserialize(message, OffenseRecord.class);
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
                acknowledge(ack);
                return;
            }
        } catch (Exception ex) {
            offenseRecordService.markHistoryFailure(idempotencyKey, ex.getMessage());
            log.log(Level.SEVERE,
                    String.format("Error processing OffenseRecord event (key=%s, action=%s)", idempotencyKey, action),
                    ex);
            throw ex;
        }

        messageProcessor.process(
                idempotencyKey,
                message,
                ack,
                "OffenseRecord",
                action,
                key -> false,
                ignored -> processPayload(payload, idempotencyKey, action),
                (key, result) -> {
                    if (result != null && result.getOffenseId() != null) {
                        offenseRecordService.markHistorySuccess(key, result.getOffenseId());
                    }
                },
                (key, ex) -> offenseRecordService.markHistoryFailure(key, ex.getMessage())
        );
    }

    private OffenseRecord processPayload(OffenseRecord payload, String idempotencyKey, String action) {
        try {
            if ("create".equalsIgnoreCase(action)) {
                payload.setOffenseId(null);
                return offenseRecordService.createOffenseRecord(payload);
            }
            if ("update".equalsIgnoreCase(action)) {
                return offenseRecordService.updateKafkaFullUpdate(payload);
            }
            log.log(Level.WARNING, "Unsupported OffenseRecord action: {0}", action);
            return null;
        } catch (StaleFullUpdateRejectedException ex) {
            logGovernance(Level.WARNING, ex.decision()
                    .withAttribute("kafkaKey", idempotencyKey)
                    .withAttribute("action", action));
            return null;
        }
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

    private void logGovernance(Level level, OffenseGovernanceDecision decision) {
        log.log(level, OffenseGovernanceLogFactory.format(decision));
    }
}
