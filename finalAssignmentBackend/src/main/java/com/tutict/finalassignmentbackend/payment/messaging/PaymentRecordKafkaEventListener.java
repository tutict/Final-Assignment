package com.tutict.finalassignmentbackend.payment.messaging;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentbackend.reliability.ReliabilityMetrics;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Component;
import org.springframework.transaction.event.TransactionPhase;
import org.springframework.transaction.event.TransactionalEventListener;

import java.util.logging.Level;
import java.util.concurrent.CompletableFuture;
import java.util.logging.Logger;

@Component
public class PaymentRecordKafkaEventListener {

    private static final Logger log = Logger.getLogger(PaymentRecordKafkaEventListener.class.getName());

    private final KafkaTemplate<String, String> kafkaTemplate;
    private final ObjectMapper objectMapper;
    private final ReliabilityMetrics reliabilityMetrics;

    public PaymentRecordKafkaEventListener(KafkaTemplate<String, String> kafkaTemplate,
                                           ObjectMapper objectMapper,
                                           ReliabilityMetrics reliabilityMetrics) {
        this.kafkaTemplate = kafkaTemplate;
        this.objectMapper = objectMapper;
        this.reliabilityMetrics = reliabilityMetrics;
    }

    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT)
    public void onPaymentRecordKafkaEvent(PaymentRecordKafkaEvent event) {
        CompletableFuture.runAsync(() -> publish(event));
    }

    private void publish(PaymentRecordKafkaEvent event) {
        try {
            String payload = objectMapper.writeValueAsString(event.paymentRecord());
            kafkaTemplate.send(event.topic(), event.idempotencyKey(), payload)
                    .whenComplete((result, error) -> {
                        if (error != null) {
                            reliabilityMetrics.kafkaPublishFailed();
                            log.log(Level.SEVERE, "Failed to send PaymentRecord Kafka message after commit", error);
                        }
                    });
        } catch (Exception ex) {
            reliabilityMetrics.kafkaPublishFailed();
            log.log(Level.SEVERE, "Failed to send PaymentRecord Kafka message after commit", ex);
        }
    }
}
