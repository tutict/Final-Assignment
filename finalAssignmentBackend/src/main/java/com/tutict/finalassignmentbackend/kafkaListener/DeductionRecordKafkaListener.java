package com.tutict.finalassignmentbackend.kafkaListener;

import com.tutict.finalassignmentbackend.common.idempotency.IdempotentKafkaMessageProcessor;
import com.tutict.finalassignmentbackend.entity.offense.DeductionRecord;
import com.tutict.finalassignmentbackend.service.offense.DeductionRecordService;
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
public class DeductionRecordKafkaListener {

    private static final Logger log = Logger.getLogger(DeductionRecordKafkaListener.class.getName());

    private final DeductionRecordService deductionRecordService;
    private final IdempotentKafkaMessageProcessor messageProcessor;

    @Autowired
    public DeductionRecordKafkaListener(DeductionRecordService deductionRecordService,
                                        IdempotentKafkaMessageProcessor messageProcessor) {
        this.deductionRecordService = deductionRecordService;
        this.messageProcessor = messageProcessor;
    }

    @KafkaListener(topics = "${kafka.topics.deduction.create:deduction_record_create}", groupId = "${kafka.groups.deduction:deductionRecordGroup}", concurrency = "3")
    public void onDeductionRecordCreate(@Header(value = KafkaHeaders.RECEIVED_KEY, required = false) byte[] rawKey,
                                        @Payload String message,
                                        Acknowledgment ack) {
        log.log(Level.INFO, "Received Kafka message for DeductionRecord create (payload omitted)");
        processMessage(asKey(rawKey), message, "create", ack);
    }

    @KafkaListener(topics = "${kafka.topics.deduction.update:deduction_record_update}", groupId = "${kafka.groups.deduction:deductionRecordGroup}", concurrency = "3")
    public void onDeductionRecordUpdate(@Header(value = KafkaHeaders.RECEIVED_KEY, required = false) byte[] rawKey,
                                        @Payload String message,
                                        Acknowledgment ack) {
        log.log(Level.INFO, "Received Kafka message for DeductionRecord update (payload omitted)");
        processMessage(asKey(rawKey), message, "update", ack);
    }

    private void processMessage(String idempotencyKey, String message, String action, Acknowledgment ack) {
        if (isBlank(idempotencyKey)) {
            log.warning("Received DeductionRecord event without idempotency key, skipping");
            acknowledge(ack);
            return;
        }
        messageProcessor.process(
                idempotencyKey,
                message,
                ack,
                "DeductionRecord",
                action,
                deductionRecordService::shouldSkipProcessing,
                payload -> processPayload(payload, action),
                (key, result) -> {
                    if (result != null && result.getDeductionId() != null) {
                        deductionRecordService.markHistorySuccess(key, result.getDeductionId());
                    }
                },
                (key, ex) -> deductionRecordService.markHistoryFailure(key, ex.getMessage())
        );
    }

    private DeductionRecord processPayload(String message, String action) {
        DeductionRecord payload = messageProcessor.deserialize(message, DeductionRecord.class);
        if ("create".equalsIgnoreCase(action)) {
            payload.setDeductionId(null);
            return deductionRecordService.createDeductionRecord(payload);
        }
        if ("update".equalsIgnoreCase(action)) {
            return deductionRecordService.updateDeductionRecord(payload);
        }
        log.log(Level.WARNING, "Unsupported DeductionRecord action: {0}", action);
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
