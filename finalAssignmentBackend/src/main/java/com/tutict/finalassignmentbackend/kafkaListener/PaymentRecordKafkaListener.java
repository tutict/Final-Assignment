package com.tutict.finalassignmentbackend.kafkaListener;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentbackend.entity.PaymentRecord;
import com.tutict.finalassignmentbackend.service.PaymentRecordService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.kafka.annotation.KafkaListener;
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
    private final ObjectMapper objectMapper;

    @Autowired
    public PaymentRecordKafkaListener(PaymentRecordService paymentRecordService,
                                      ObjectMapper objectMapper) {
        this.paymentRecordService = paymentRecordService;
        this.objectMapper = objectMapper;
    }

    @KafkaListener(topics = "payment_record_create", groupId = "paymentRecordGroup", concurrency = "3")
    public void onPaymentRecordCreate(@Header(value = KafkaHeaders.RECEIVED_KEY, required = false) byte[] rawKey,
                                      @Payload String message) {
        log.log(Level.INFO, "Received Kafka message for PaymentRecord create: {0}", message);
        Thread.ofVirtual().start(() -> processMessage(asKey(rawKey), message, "create"));
    }

    @KafkaListener(topics = "payment_record_update", groupId = "paymentRecordGroup", concurrency = "3")
    public void onPaymentRecordUpdate(@Header(value = KafkaHeaders.RECEIVED_KEY, required = false) byte[] rawKey,
                                      @Payload String message) {
        log.log(Level.INFO, "Received Kafka message for PaymentRecord update: {0}", message);
        Thread.ofVirtual().start(() -> processMessage(asKey(rawKey), message, "update"));
    }

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
                log.log(Level.INFO, "Skipping duplicate PaymentRecord event (key={0}, action={1})",
                        new Object[]{idempotencyKey, action});
                return;
            }

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
            log.log(Level.SEVERE, "Failed to deserialize PaymentRecord message: {0}", message);
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
