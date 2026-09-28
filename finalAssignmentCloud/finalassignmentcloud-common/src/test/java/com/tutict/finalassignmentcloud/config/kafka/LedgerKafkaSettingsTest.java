package com.tutict.finalassignmentcloud.config.kafka;

import static org.junit.jupiter.api.Assertions.assertEquals;

import java.util.Map;
import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.apache.kafka.clients.producer.ProducerConfig;
import org.apache.kafka.common.TopicPartition;
import org.junit.jupiter.api.Test;

class LedgerKafkaSettingsTest {

    @Test
    void producerIsBoundedAndIdempotent() {
        Map<String, Object> props = LedgerKafkaSettings.producer("localhost:9092");
        assertEquals(3, props.get(ProducerConfig.RETRIES_CONFIG));
        assertEquals(10_000, props.get(ProducerConfig.DELIVERY_TIMEOUT_MS_CONFIG));
        assertEquals("all", props.get(ProducerConfig.ACKS_CONFIG));
        assertEquals(true, props.get(ProducerConfig.ENABLE_IDEMPOTENCE_CONFIG));
        assertEquals(5, props.get(ProducerConfig.MAX_IN_FLIGHT_REQUESTS_PER_CONNECTION));
        assertEquals("com.tutict.finalassignmentcloud.observability.TraceIdProducerInterceptor",
                props.get(ProducerConfig.INTERCEPTOR_CLASSES_CONFIG));
    }

    @Test
    void consumerRetriesThreeTimesThenUsesExistingDeadLetterTopic() {
        assertEquals(3, LedgerKafkaSettings.consumerBackOff().getMaxRetries());
        ConsumerRecord<String, String> record = new ConsumerRecord<>("payment_record_create", 2, 0L, "key", "body");
        TopicPartition destination = LedgerKafkaSettings.deadLetterDestination().apply(record, new IllegalStateException("down"));
        assertEquals("payment_record_create.DLT", destination.topic());
        assertEquals(2, destination.partition());
        TopicPartition offense = LedgerKafkaSettings.deadLetterDestination().apply(
                new ConsumerRecord<>("offense_record_create", 0, 1L, null, "{}"),
                new IllegalStateException("down"));
        assertEquals("offense_record_create.DLT", offense.topic());
    }
}
