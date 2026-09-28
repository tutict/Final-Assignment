package com.tutict.finalassignmentcloud.traffic.reliability;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import io.micrometer.core.instrument.Counter;
import org.springframework.kafka.core.KafkaTemplate;

import java.util.logging.Level;
import java.util.logging.Logger;

public final class PaymentKafkaPublish {

    private PaymentKafkaPublish() {
    }

    public static void send(KafkaTemplate<String, String> kafkaTemplate,
                            ObjectMapper objectMapper,
                            Counter failures,
                            String topic,
                            String key,
                            Object payload,
                            Logger log) {
        try {
            String body = objectMapper.writeValueAsString(payload);
            kafkaTemplate.send(topic, key, body).whenComplete((result, error) -> {
                if (error != null) {
                    increment(failures);
                    log.log(Level.WARNING, "Failed to send PaymentRecord Kafka message", error);
                }
            });
        } catch (JsonProcessingException | RuntimeException ex) {
            increment(failures);
            log.log(Level.WARNING, "Failed to send PaymentRecord Kafka message", ex);
        }
    }

    private static void increment(Counter failures) {
        if (failures != null) {
            failures.increment();
        }
    }
}
