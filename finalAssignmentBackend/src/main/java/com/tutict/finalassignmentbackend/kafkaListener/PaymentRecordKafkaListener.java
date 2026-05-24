package com.tutict.finalassignmentbackend.kafkaListener;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentbackend.entity.payment.PaymentRecord;
import com.tutict.finalassignmentbackend.payment.governance.PaymentGovernanceClassifier;
import com.tutict.finalassignmentbackend.payment.governance.PaymentGovernanceLogFactory;
import com.tutict.finalassignmentbackend.payment.governance.PaymentGovernanceSource;
import com.tutict.finalassignmentbackend.service.payment.PaymentRecordService;
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
public class PaymentRecordKafkaListener {

    private static final Logger log = Logger.getLogger(PaymentRecordKafkaListener.class.getName());

    private final PaymentRecordService paymentRecordService;
    private final ObjectMapper objectMapper;
    private final PaymentGovernanceClassifier paymentGovernanceClassifier;

    // 构造器注入依赖
    @Autowired
    public PaymentRecordKafkaListener(PaymentRecordService paymentRecordService,
                                      ObjectMapper objectMapper) {
        this.paymentRecordService = paymentRecordService;
        this.objectMapper = objectMapper;
        this.paymentGovernanceClassifier = new PaymentGovernanceClassifier();
    }

    // 监听 Kafka 消息
    @KafkaListener(topics = "${kafka.topics.payment.create:payment_record_create}", groupId = "${kafka.groups.payment:paymentRecordGroup}", concurrency = "3")
    public void onPaymentRecordCreate(@Header(value = KafkaHeaders.RECEIVED_KEY, required = false) byte[] rawKey,
                                      @Payload String message,
                                      Acknowledgment ack) {
        log.log(Level.INFO, "Received Kafka message for PaymentRecord create (payload omitted)");
        processMessage(asKey(rawKey), message, "create");
        ack.acknowledge();
    }

    // 监听 Kafka 消息
    @KafkaListener(topics = "${kafka.topics.payment.update:payment_record_update}", groupId = "${kafka.groups.payment:paymentRecordGroup}", concurrency = "3")
    public void onPaymentRecordUpdate(@Header(value = KafkaHeaders.RECEIVED_KEY, required = false) byte[] rawKey,
                                      @Payload String message,
                                      Acknowledgment ack) {
        log.log(Level.INFO, "Received Kafka message for PaymentRecord update (payload omitted)");
        processMessage(asKey(rawKey), message, "update");
        ack.acknowledge();
    }

    // 统一处理消息并执行业务逻辑
    private void processMessage(String idempotencyKey, String message, String action) {
        if (isBlank(idempotencyKey)) {
            log.warning("Received PaymentRecord event without idempotency key, skipping");
            return;
        }

        PaymentRecord payload = deserializeMessage(message);
        if (payload == null) {
            log.warning("Received PaymentRecord event with empty payload, skipping");
            return;
        }

        try {
            if (paymentRecordService.shouldSkipProcessing(idempotencyKey)) {
                logPaymentGovernance(PaymentGovernanceLogFactory.noOpSuppressed(
                        PaymentGovernanceSource.KAFKA,
                        paymentGovernanceClassifier.classifyKafkaMutation(action, true),
                        payload,
                        action,
                        idempotencyKey
                ));
                return;
            }
            logPaymentGovernance(PaymentGovernanceLogFactory.shadowClassification(
                    PaymentGovernanceSource.KAFKA,
                    paymentGovernanceClassifier.classifyKafkaMutation(action, false),
                    payload,
                    action
            ));

            PaymentRecord result;
            if ("create".equalsIgnoreCase(action)) {
                payload.setPaymentId(null);
                result = paymentRecordService.createPaymentRecord(payload);
            } else if ("update".equalsIgnoreCase(action)) {
                result = paymentRecordService.updatePaymentRecord(payload);
            } else {
                log.log(Level.WARNING, "Unsupported PaymentRecord action: {0}", action);
                return;
            }

            paymentRecordService.markHistorySuccess(idempotencyKey, result.getPaymentId());
        } catch (Exception ex) {
            paymentRecordService.markHistoryFailure(idempotencyKey, ex.getMessage());
            log.log(Level.SEVERE,
                    String.format("Error processing PaymentRecord event (key=%s, action=%s)", idempotencyKey, action),
                    ex);
            throw ex;
        }
    }
    private PaymentRecord deserializeMessage(String message) {
        try {
            return objectMapper.readValue(message, PaymentRecord.class);
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

    private void logPaymentGovernance(String payload) {
        log.log(Level.INFO, payload);
    }
}
