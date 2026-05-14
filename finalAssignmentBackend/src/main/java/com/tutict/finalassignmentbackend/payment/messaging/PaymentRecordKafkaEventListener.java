package com.tutict.finalassignmentbackend.payment.messaging;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Component;
import org.springframework.transaction.event.TransactionPhase;
import org.springframework.transaction.event.TransactionalEventListener;

import java.util.logging.Level;
import java.util.logging.Logger;

@Component
public class PaymentRecordKafkaEventListener {

    private static final Logger log = Logger.getLogger(PaymentRecordKafkaEventListener.class.getName());

    private final KafkaTemplate<String, String> kafkaTemplate;
    private final ObjectMapper objectMapper;

    public PaymentRecordKafkaEventListener(KafkaTemplate<String, String> kafkaTemplate,
                                           ObjectMapper objectMapper) {
        this.kafkaTemplate = kafkaTemplate;
        this.objectMapper = objectMapper;
    }

    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT)
    public void onPaymentRecordKafkaEvent(PaymentRecordKafkaEvent event) {
        try {
            String payload = objectMapper.writeValueAsString(event.paymentRecord());
            kafkaTemplate.send(event.topic(), event.idempotencyKey(), payload);
        } catch (Exception ex) {
            log.log(Level.SEVERE, "Failed to send PaymentRecord Kafka message after commit", ex);
            throw new RuntimeException("Failed to send PaymentRecord event", ex);
        }
    }
}
