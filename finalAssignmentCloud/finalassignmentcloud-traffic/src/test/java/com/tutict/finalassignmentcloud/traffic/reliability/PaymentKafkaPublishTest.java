package com.tutict.finalassignmentcloud.traffic.reliability;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.nullable;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

import com.fasterxml.jackson.databind.ObjectMapper;
import io.micrometer.core.instrument.Counter;
import io.micrometer.core.instrument.simple.SimpleMeterRegistry;
import java.util.concurrent.CompletableFuture;
import java.util.logging.Logger;
import org.junit.jupiter.api.Test;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.kafka.support.SendResult;

class PaymentKafkaPublishTest {

    @Test
    void synchronousSendFailureIncrementsCounter() {
        KafkaTemplate<String, String> template = mock(KafkaTemplate.class);
        when(template.send(anyString(), nullable(String.class), anyString()))
                .thenThrow(new RuntimeException("kafka down"));
        Counter counter = counter();

        PaymentKafkaPublish.send(template, new ObjectMapper(), counter, "payment_record_create", null, "body", logger());

        assertEquals(1.0, counter.count());
    }

    @Test
    void asynchronousSendFailureIncrementsCounter() {
        KafkaTemplate<String, String> template = mock(KafkaTemplate.class);
        CompletableFuture<SendResult<String, String>> future = new CompletableFuture<>();
        when(template.send(anyString(), nullable(String.class), anyString())).thenReturn(future);
        Counter counter = counter();

        PaymentKafkaPublish.send(template, new ObjectMapper(), counter, "payment_record_create", "key", "body", logger());
        assertEquals(0.0, counter.count());

        future.completeExceptionally(new RuntimeException("delivery failed"));

        assertEquals(1.0, counter.count());
    }

    @Test
    void successfulSendDoesNotIncrementCounter() {
        KafkaTemplate<String, String> template = mock(KafkaTemplate.class);
        when(template.send(anyString(), nullable(String.class), anyString()))
                .thenReturn(CompletableFuture.completedFuture(null));
        Counter counter = counter();

        PaymentKafkaPublish.send(template, new ObjectMapper(), counter, "payment_record_create", "key", "body", logger());

        assertEquals(0.0, counter.count());
    }

    private static Counter counter() {
        return Counter.builder("kafka_publish_failed_total").register(new SimpleMeterRegistry());
    }

    private static Logger logger() {
        return Logger.getLogger("payment-kafka-publish-test");
    }
}
