package com.tutict.finalassignmentbackend.service.messaging;

import com.tutict.finalassignmentbackend.exception.BusinessException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Component;
import org.springframework.transaction.support.TransactionSynchronization;
import org.springframework.transaction.support.TransactionSynchronizationManager;

import java.time.Duration;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.TimeoutException;

@Component
public class KafkaMessageSender {

    private static final Logger log = LoggerFactory.getLogger(KafkaMessageSender.class);

    private final KafkaTemplate<String, String> kafkaTemplate;

    public KafkaMessageSender(KafkaTemplate<String, String> kafkaTemplate) {
        this.kafkaTemplate = kafkaTemplate;
    }

    public void sendAsync(String topic, String key, String message) {
        kafkaTemplate.send(topic, key, message).whenComplete((result, ex) -> {
            if (ex != null) {
                log.error("Kafka send failed: topic={}, key={}, error={}",
                        topic, key, ex.getMessage(), ex);
                return;
            }
            log.debug("Kafka send success: topic={}, partition={}, offset={}",
                    topic,
                    result.getRecordMetadata().partition(),
                    result.getRecordMetadata().offset());
        });
    }

    public void sendAfterCommit(String topic, String key, String message) {
        if (!TransactionSynchronizationManager.isSynchronizationActive()) {
            sendAsync(topic, key, message);
            return;
        }
        TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
            @Override
            public void afterCommit() {
                sendAsync(topic, key, message);
            }
        });
    }

    public void sendSync(String topic, String key, String message, Duration timeout) {
        try {
            kafkaTemplate.send(topic, key, message)
                    .get(timeout.toMillis(), TimeUnit.MILLISECONDS);
        } catch (TimeoutException e) {
            throw new BusinessException("KAFKA_TIMEOUT", "消息发送超时，请重试");
        } catch (Exception e) {
            throw new BusinessException("KAFKA_SEND_FAILED", "消息发送失败：" + e.getMessage());
        }
    }
}
