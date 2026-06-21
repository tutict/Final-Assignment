package com.tutict.finalassignmentbackend.kafkaListener;

import com.tutict.finalassignmentbackend.common.idempotency.IdempotentKafkaMessageProcessor;
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
public class PaymentRecordKafkaListener {

    private static final Logger log = Logger.getLogger(PaymentRecordKafkaListener.class.getName());

    private final PaymentRecordService paymentRecordService;
    private final IdempotentKafkaMessageProcessor messageProcessor;
    private final PaymentGovernanceClassifier paymentGovernanceClassifier;

    @Autowired
    public PaymentRecordKafkaListener(PaymentRecordService paymentRecordService,
                                      IdempotentKafkaMessageProcessor messageProcessor) {
        this.paymentRecordService = paymentRecordService;
        this.messageProcessor = messageProcessor;
        this.paymentGovernanceClassifier = new PaymentGovernanceClassifier();
    }

    @KafkaListener(topics = "${kafka.topics.payment.create:payment_record_create}", groupId = "${kafka.groups.payment:paymentRecordGroup}", concurrency = "3")
    public void onPaymentRecordCreate(@Header(value = KafkaHeaders.RECEIVED_KEY, required = false) byte[] rawKey,
                                      @Payload String message,
                                      Acknowledgment ack) {
        log.log(Level.INFO, "Received Kafka message for PaymentRecord create (payload omitted)");
        processMessage(asKey(rawKey), message, "create", ack);
    }

    @KafkaListener(topics = "${kafka.topics.payment.update:payment_record_update}", groupId = "${kafka.groups.payment:paymentRecordGroup}", concurrency = "3")
    public void onPaymentRecordUpdate(@Header(value = KafkaHeaders.RECEIVED_KEY, required = false) byte[] rawKey,
                                      @Payload String message,
                                      Acknowledgment ack) {
        log.log(Level.INFO, "Received Kafka message for PaymentRecord update (payload omitted)");
        processMessage(asKey(rawKey), message, "update", ack);
    }

    private void processMessage(String idempotencyKey, String message, String action, Acknowledgment ack) {
        if (isBlank(idempotencyKey)) {
            log.warning("Received PaymentRecord event without idempotency key, skipping");
            acknowledge(ack);
            return;
        }

        PaymentRecord payload = messageProcessor.deserialize(message, PaymentRecord.class);
        try {
            if (paymentRecordService.shouldSkipProcessing(idempotencyKey)) {
                logPaymentGovernance(PaymentGovernanceLogFactory.noOpSuppressed(
                        PaymentGovernanceSource.KAFKA,
                        paymentGovernanceClassifier.classifyKafkaMutation(action, true),
                        payload,
                        action,
                        idempotencyKey
                ));
                acknowledge(ack);
                return;
            }
        } catch (Exception ex) {
            paymentRecordService.markHistoryFailure(idempotencyKey, ex.getMessage());
            log.log(Level.SEVERE,
                    String.format("Error processing PaymentRecord event (key=%s, action=%s)", idempotencyKey, action),
                    ex);
            throw ex;
        }

        messageProcessor.process(
                idempotencyKey,
                message,
                ack,
                "PaymentRecord",
                action,
                key -> false,
                ignored -> processPayload(payload, action),
                (key, result) -> {
                    if (result != null && result.getPaymentId() != null) {
                        paymentRecordService.markHistorySuccess(key, result.getPaymentId());
                    }
                },
                (key, ex) -> paymentRecordService.markHistoryFailure(key, ex.getMessage())
        );
    }

    private PaymentRecord processPayload(PaymentRecord payload, String action) {
        logPaymentGovernance(PaymentGovernanceLogFactory.shadowClassification(
                PaymentGovernanceSource.KAFKA,
                paymentGovernanceClassifier.classifyKafkaMutation(action, false),
                payload,
                action
        ));

        if ("create".equalsIgnoreCase(action)) {
            payload.setPaymentId(null);
            return paymentRecordService.createPaymentRecord(payload);
        }
        if ("update".equalsIgnoreCase(action)) {
            return paymentRecordService.updatePaymentRecord(payload);
        }
        log.log(Level.WARNING, "Unsupported PaymentRecord action: {0}", action);
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

    private void logPaymentGovernance(String payload) {
        log.log(Level.INFO, payload);
    }
}
