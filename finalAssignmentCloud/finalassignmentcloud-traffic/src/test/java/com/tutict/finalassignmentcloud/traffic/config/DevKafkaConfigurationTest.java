package com.tutict.finalassignmentcloud.traffic.config;

import static org.junit.jupiter.api.Assertions.assertEquals;

import java.util.Map;
import org.apache.kafka.clients.producer.ProducerConfig;
import org.junit.jupiter.api.Test;

class DevKafkaConfigurationTest {

    @Test
    void producerRetriesAndDeliveryTimeoutAreBounded() {
        DevKafkaConfiguration config = new DevKafkaConfiguration("localhost:9092");
        Map<String, Object> props = config.producerConfig();

        assertEquals(3, props.get(ProducerConfig.RETRIES_CONFIG));
        assertEquals(10_000, props.get(ProducerConfig.DELIVERY_TIMEOUT_MS_CONFIG));
        assertEquals(3_000, props.get(ProducerConfig.REQUEST_TIMEOUT_MS_CONFIG));
        assertEquals(500, props.get(ProducerConfig.MAX_BLOCK_MS_CONFIG));
        assertEquals("all", props.get(ProducerConfig.ACKS_CONFIG));
        assertEquals(true, props.get(ProducerConfig.ENABLE_IDEMPOTENCE_CONFIG));
        assertEquals(5, props.get(ProducerConfig.MAX_IN_FLIGHT_REQUESTS_PER_CONNECTION));
    }
}
