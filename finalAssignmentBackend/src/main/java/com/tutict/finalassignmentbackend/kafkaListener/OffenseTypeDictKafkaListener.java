package com.tutict.finalassignmentbackend.kafkaListener;

import com.tutict.finalassignmentbackend.common.idempotency.IdempotentKafkaMessageProcessor;
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
public class OffenseTypeDictKafkaListener {

    private static final Logger log = Logger.getLogger(OffenseTypeDictKafkaListener.class.getName());

    private final OffenseTypeDictService offenseTypeDictService;
    private final IdempotentKafkaMessageProcessor messageProcessor;

    @Autowired
    public OffenseTypeDictKafkaListener(OffenseTypeDictService offenseTypeDictService,
                                        IdempotentKafkaMessageProcessor messageProcessor) {
        this.offenseTypeDictService = offenseTypeDictService;
        this.messageProcessor = messageProcessor;
    }

    @KafkaListener(topics = "${kafka.topics.offense-type-dict.create:offense_type_dict_create}", groupId = "${kafka.groups.offense-type-dict:offenseTypeDictGroup}", concurrency = "3")
    public void onOffenseTypeDictCreate(@Header(value = KafkaHeaders.RECEIVED_KEY, required = false) byte[] rawKey,
                                        @Payload String message,
                                        Acknowledgment ack) {
        log.log(Level.INFO, "Received Kafka message for OffenseTypeDict create (payload omitted)");
        processMessage(asKey(rawKey), message, "create", ack);
    }

    @KafkaListener(topics = "${kafka.topics.offense-type-dict.update:offense_type_dict_update}", groupId = "${kafka.groups.offense-type-dict:offenseTypeDictGroup}", concurrency = "3")
    public void onOffenseTypeDictUpdate(@Header(value = KafkaHeaders.RECEIVED_KEY, required = false) byte[] rawKey,
                                        @Payload String message,
                                        Acknowledgment ack) {
        log.log(Level.INFO, "Received Kafka message for OffenseTypeDict update (payload omitted)");
        processMessage(asKey(rawKey), message, "update", ack);
    }

    private void processMessage(String idempotencyKey, String message, String action, Acknowledgment ack) {
        if (isBlank(idempotencyKey)) {
            log.warning("Received OffenseTypeDict event without idempotency key, skipping");
            acknowledge(ack);
            return;
        }
        messageProcessor.process(
                idempotencyKey,
                message,
                ack,
                "OffenseTypeDict",
                action,
                offenseTypeDictService::shouldSkipProcessing,
                payload -> processPayload(payload, action),
                (key, result) -> {
                    if (result != null && result.getTypeId() != null) {
                        offenseTypeDictService.markHistorySuccess(key, result.getTypeId());
                    }
                },
                (key, ex) -> offenseTypeDictService.markHistoryFailure(key, ex.getMessage())
        );
    }

    private OffenseTypeDict processPayload(String message, String action) {
        OffenseTypeDict payload = messageProcessor.deserialize(message, OffenseTypeDict.class);
        if ("create".equalsIgnoreCase(action)) {
            payload.setTypeId(null);
            return offenseTypeDictService.createDict(payload);
        }
        if ("update".equalsIgnoreCase(action)) {
            return offenseTypeDictService.updateDict(payload);
        }
        log.log(Level.WARNING, "Unsupported OffenseTypeDict action: {0}", action);
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
