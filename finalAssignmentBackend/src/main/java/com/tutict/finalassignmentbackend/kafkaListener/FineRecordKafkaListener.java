package com.tutict.finalassignmentbackend.kafkaListener;

import com.tutict.finalassignmentbackend.common.idempotency.IdempotentKafkaMessageProcessor;
import com.tutict.finalassignmentbackend.entity.offense.FineRecord;
import com.tutict.finalassignmentbackend.service.offense.FineRecordService;
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
public class FineRecordKafkaListener {

    private static final Logger log = Logger.getLogger(FineRecordKafkaListener.class.getName());

    private final FineRecordService fineRecordService;
    private final IdempotentKafkaMessageProcessor messageProcessor;

    @Autowired
    public FineRecordKafkaListener(FineRecordService fineRecordService,
                                   IdempotentKafkaMessageProcessor messageProcessor) {
        this.fineRecordService = fineRecordService;
        this.messageProcessor = messageProcessor;
    }

    @KafkaListener(topics = "${kafka.topics.fine.create:fine_record_create}", groupId = "${kafka.groups.fine:fineRecordGroup}", concurrency = "3")
    public void onFineRecordCreate(@Header(value = KafkaHeaders.RECEIVED_KEY, required = false) byte[] rawKey,
                                   @Payload String message,
                                   Acknowledgment ack) {
        log.log(Level.INFO, "Received Kafka message for FineRecord create (payload omitted)");
        processMessage(asKey(rawKey), message, "create", ack);
    }

    @KafkaListener(topics = "${kafka.topics.fine.update:fine_record_update}", groupId = "${kafka.groups.fine:fineRecordGroup}", concurrency = "3")
    public void onFineRecordUpdate(@Header(value = KafkaHeaders.RECEIVED_KEY, required = false) byte[] rawKey,
                                   @Payload String message,
                                   Acknowledgment ack) {
        log.log(Level.INFO, "Received Kafka message for FineRecord update (payload omitted)");
        processMessage(asKey(rawKey), message, "update", ack);
    }

    private void processMessage(String idempotencyKey, String message, String action, Acknowledgment ack) {
        if (isBlank(idempotencyKey)) {
            log.warning("Received FineRecord event without idempotency key, skipping");
            acknowledge(ack);
            return;
        }
        messageProcessor.process(
                idempotencyKey,
                message,
                ack,
                "FineRecord",
                action,
                fineRecordService::shouldSkipProcessing,
                payload -> processPayload(payload, action),
                (key, result) -> {
                    if (result != null && result.getFineId() != null) {
                        fineRecordService.markHistorySuccess(key, result.getFineId());
                    }
                },
                (key, ex) -> fineRecordService.markHistoryFailure(key, ex.getMessage())
        );
    }

    private FineRecord processPayload(String message, String action) {
        FineRecord payload = messageProcessor.deserialize(message, FineRecord.class);
        if ("create".equalsIgnoreCase(action)) {
            payload.setFineId(null);
            return fineRecordService.createFineRecord(payload);
        }
        if ("update".equalsIgnoreCase(action)) {
            return fineRecordService.updateFineRecord(payload);
        }
        log.log(Level.WARNING, "Unsupported FineRecord action: {0}", action);
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
