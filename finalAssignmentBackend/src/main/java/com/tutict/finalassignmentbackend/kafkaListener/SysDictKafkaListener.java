package com.tutict.finalassignmentbackend.kafkaListener;

import com.tutict.finalassignmentbackend.common.idempotency.IdempotentKafkaMessageProcessor;
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
public class SysDictKafkaListener {

    private static final Logger log = Logger.getLogger(SysDictKafkaListener.class.getName());

    private final SysDictService sysDictService;
    private final IdempotentKafkaMessageProcessor messageProcessor;

    @Autowired
    public SysDictKafkaListener(SysDictService sysDictService,
                                IdempotentKafkaMessageProcessor messageProcessor) {
        this.sysDictService = sysDictService;
        this.messageProcessor = messageProcessor;
    }

    @KafkaListener(topics = "${kafka.topics.sys-dict.create:sys_dict_create}", groupId = "${kafka.groups.sys-dict:sysDictGroup}", concurrency = "3")
    public void onSysDictCreate(@Header(value = KafkaHeaders.RECEIVED_KEY, required = false) byte[] rawKey,
                                @Payload String message,
                                Acknowledgment ack) {
        log.log(Level.INFO, "Received Kafka message for SysDict create (payload omitted)");
        processMessage(asKey(rawKey), message, "create", ack);
    }

    @KafkaListener(topics = "${kafka.topics.sys-dict.update:sys_dict_update}", groupId = "${kafka.groups.sys-dict:sysDictGroup}", concurrency = "3")
    public void onSysDictUpdate(@Header(value = KafkaHeaders.RECEIVED_KEY, required = false) byte[] rawKey,
                                @Payload String message,
                                Acknowledgment ack) {
        log.log(Level.INFO, "Received Kafka message for SysDict update (payload omitted)");
        processMessage(asKey(rawKey), message, "update", ack);
    }

    private void processMessage(String idempotencyKey, String message, String action, Acknowledgment ack) {
        if (isBlank(idempotencyKey)) {
            log.warning("Received SysDict event without idempotency key, skipping");
            acknowledge(ack);
            return;
        }
        messageProcessor.process(
                idempotencyKey,
                message,
                ack,
                "SysDict",
                action,
                sysDictService::shouldSkipProcessing,
                payload -> processPayload(payload, action),
                (key, result) -> {
                    if (result != null && result.getDictId() != null) {
                        sysDictService.markHistorySuccess(key, result.getDictId());
                    }
                },
                (key, ex) -> sysDictService.markHistoryFailure(key, ex.getMessage())
        );
    }

    private SysDict processPayload(String message, String action) {
        SysDict payload = messageProcessor.deserialize(message, SysDict.class);
        if ("create".equalsIgnoreCase(action)) {
            payload.setDictId(null);
            return sysDictService.createSysDict(payload);
        }
        if ("update".equalsIgnoreCase(action)) {
            return sysDictService.updateSysDict(payload);
        }
        log.log(Level.WARNING, "Unsupported SysDict action: {0}", action);
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
