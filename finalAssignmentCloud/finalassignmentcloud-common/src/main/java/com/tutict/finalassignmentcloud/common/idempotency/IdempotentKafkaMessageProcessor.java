package com.tutict.finalassignmentcloud.common.idempotency;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.springframework.kafka.support.Acknowledgment;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;

import java.util.function.BiConsumer;
import java.util.function.Function;
import java.util.logging.Level;
import java.util.logging.Logger;

@Component
public class IdempotentKafkaMessageProcessor {

    private static final Logger LOG = Logger.getLogger(IdempotentKafkaMessageProcessor.class.getName());

    private final ObjectMapper objectMapper;

    public IdempotentKafkaMessageProcessor(ObjectMapper objectMapper) {
        this.objectMapper = objectMapper;
    }

    public <T> void process(
            ConsumerRecord<String, String> record,
            Acknowledgment acknowledgment,
            String entityName,
            String action,
            Function<String, Boolean> duplicateCheck,
            ThrowingFunction<String, T> handler,
            BiConsumer<String, T> markSuccess,
            BiConsumer<String, Exception> markFailure
    ) {
        process(
                record == null ? null : record.key(),
                record == null ? null : record.value(),
                acknowledgment,
                entityName,
                action,
                duplicateCheck,
                handler,
                markSuccess,
                markFailure
        );
    }

    public <T> void process(
            String idempotencyKey,
            String payload,
            Acknowledgment acknowledgment,
            String entityName,
            String action,
            Function<String, Boolean> duplicateCheck,
            ThrowingFunction<String, T> handler,
            BiConsumer<String, T> markSuccess,
            BiConsumer<String, Exception> markFailure
    ) {
        boolean keyed = StringUtils.hasText(idempotencyKey);
        if (keyed && duplicateCheck != null && Boolean.TRUE.equals(duplicateCheck.apply(idempotencyKey))) {
            LOG.log(Level.INFO, "Skipping duplicate {0} message: key={1}, action={2}",
                    new Object[]{entityName, idempotencyKey, action});
            acknowledge(acknowledgment);
            return;
        }
        try {
            T result = handler.apply(payload);
            if (keyed && markSuccess != null) {
                markSuccess.accept(idempotencyKey, result);
            }
            acknowledge(acknowledgment);
        } catch (Exception ex) {
            if (keyed && markFailure != null) {
                markFailure.accept(idempotencyKey, ex);
            }
            LOG.log(Level.SEVERE, entityName + " Kafka message processing failed", ex);
            throw propagate(ex);
        }
    }

    public <T> T deserialize(String payload, Class<T> targetType) {
        try {
            return objectMapper.readValue(payload, targetType);
        } catch (Exception ex) {
            throw new IllegalArgumentException("Failed to deserialize Kafka message", ex);
        }
    }

    private void acknowledge(Acknowledgment acknowledgment) {
        if (acknowledgment != null) {
            acknowledgment.acknowledge();
        }
    }

    private RuntimeException propagate(Exception ex) {
        return ex instanceof RuntimeException runtime ? runtime : new RuntimeException(ex);
    }

    @FunctionalInterface
    public interface ThrowingFunction<T, R> {
        R apply(T value) throws Exception;
    }
}
