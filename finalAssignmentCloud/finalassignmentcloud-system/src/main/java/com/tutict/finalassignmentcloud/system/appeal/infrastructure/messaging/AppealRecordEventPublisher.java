package com.tutict.finalassignmentcloud.system.appeal.infrastructure.messaging;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentcloud.entity.appeal.AppealRecord;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.support.TransactionSynchronization;
import org.springframework.transaction.support.TransactionSynchronizationManager;

import java.util.logging.Level;
import java.util.logging.Logger;

@Service
public class AppealRecordEventPublisher {

    private static final Logger log = Logger.getLogger(AppealRecordEventPublisher.class.getName());

    private final KafkaTemplate<String, String> kafkaTemplate;
    private final ObjectMapper objectMapper;

    public AppealRecordEventPublisher(
            KafkaTemplate<String, String> kafkaTemplate,
            ObjectMapper objectMapper
    ) {
        this.kafkaTemplate = kafkaTemplate;
        this.objectMapper = objectMapper;
    }

    public void publishAfterCommit(String topic, String idempotencyKey, AppealRecord appealRecord) {
        runAfterCommit(() -> publish(topic, idempotencyKey, appealRecord));
    }

    public void publish(String topic, String idempotencyKey, AppealRecord appealRecord) {
        try {
            String payload = objectMapper.writeValueAsString(appealRecord);
            kafkaTemplate.send(topic, idempotencyKey, payload);
        } catch (Exception ex) {
            log.log(Level.WARNING, "Failed to send appeal Kafka message", ex);
            throw new RuntimeException("Failed to send appeal record event", ex);
        }
    }

    private static void runAfterCommit(Runnable action) {
        if (!TransactionSynchronizationManager.isSynchronizationActive()) {
            action.run();
            return;
        }
        TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
            @Override
            public void afterCommit() {
                action.run();
            }
        });
    }
}
