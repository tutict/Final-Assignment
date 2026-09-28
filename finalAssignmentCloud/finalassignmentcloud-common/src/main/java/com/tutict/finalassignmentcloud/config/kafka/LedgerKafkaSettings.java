package com.tutict.finalassignmentcloud.config.kafka;

import com.fasterxml.jackson.core.JsonProcessingException;
import java.util.HashMap;
import java.util.Map;
import java.util.function.BiFunction;
import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.apache.kafka.clients.producer.ProducerConfig;
import org.apache.kafka.common.TopicPartition;
import org.apache.kafka.common.serialization.StringSerializer;
import com.tutict.finalassignmentcloud.observability.TraceIdProducerInterceptor;
import com.tutict.finalassignmentcloud.observability.TraceIdRecordInterceptor;
import org.springframework.kafka.config.ConcurrentKafkaListenerContainerFactory;
import org.springframework.kafka.core.KafkaOperations;
import org.springframework.kafka.listener.DeadLetterPublishingRecoverer;
import org.springframework.kafka.listener.DefaultErrorHandler;
import org.springframework.kafka.support.ExponentialBackOffWithMaxRetries;

public final class LedgerKafkaSettings {

    public static final int MAX_CONSUMER_RETRIES = 3;

    private LedgerKafkaSettings() {
    }

    public static Map<String, Object> producer(String bootstrapServers) {
        Map<String, Object> props = new HashMap<>();
        props.put(ProducerConfig.BOOTSTRAP_SERVERS_CONFIG, bootstrapServers);
        props.put(ProducerConfig.KEY_SERIALIZER_CLASS_CONFIG, StringSerializer.class);
        props.put(ProducerConfig.VALUE_SERIALIZER_CLASS_CONFIG, StringSerializer.class);
        props.put(ProducerConfig.ENABLE_IDEMPOTENCE_CONFIG, true);
        props.put(ProducerConfig.ACKS_CONFIG, "all");
        props.put(ProducerConfig.RETRIES_CONFIG, 3);
        props.put(ProducerConfig.DELIVERY_TIMEOUT_MS_CONFIG, 10_000);
        props.put(ProducerConfig.REQUEST_TIMEOUT_MS_CONFIG, 3_000);
        props.put(ProducerConfig.MAX_BLOCK_MS_CONFIG, 500);
        props.put(ProducerConfig.MAX_IN_FLIGHT_REQUESTS_PER_CONNECTION, 5);
        props.put(ProducerConfig.INTERCEPTOR_CLASSES_CONFIG, TraceIdProducerInterceptor.class.getName());
        return props;
    }


    public static void rememberTrace(ConcurrentKafkaListenerContainerFactory<String, String> factory) {
        factory.setRecordInterceptor(new TraceIdRecordInterceptor());
    }

    public static BiFunction<ConsumerRecord<?, ?>, Exception, TopicPartition> deadLetterDestination() {
        return (record, exception) -> new TopicPartition(record.topic() + ".DLT", record.partition());
    }

    public static ExponentialBackOffWithMaxRetries consumerBackOff() {
        ExponentialBackOffWithMaxRetries backOff = new ExponentialBackOffWithMaxRetries(MAX_CONSUMER_RETRIES);
        backOff.setInitialInterval(200L);
        backOff.setMultiplier(2.0);
        backOff.setMaxInterval(1000L);
        return backOff;
    }

    public static DefaultErrorHandler consumerErrorHandler(KafkaOperations<?, ?> template) {
        DefaultErrorHandler handler = new DefaultErrorHandler(
                new DeadLetterPublishingRecoverer(template, deadLetterDestination()),
                consumerBackOff());
        handler.addNotRetryableExceptions(IllegalArgumentException.class, JsonProcessingException.class);
        handler.setCommitRecovered(true);
        return handler;
    }
}
