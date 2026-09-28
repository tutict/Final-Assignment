package com.tutict.finalassignmentbackend.config;

import static org.assertj.core.api.Assertions.assertThat;

import java.lang.reflect.Field;
import java.lang.reflect.Method;
import java.util.Map;
import org.apache.kafka.clients.producer.ProducerConfig;
import org.junit.jupiter.api.Test;

class KafkaProducerConfigTest {

    @Test
    void producerRetriesAndDeliveryTimeoutAreBounded() throws Exception {
        KafkaProducerConfig config = new KafkaProducerConfig();
        Field bootstrap = KafkaProducerConfig.class.getDeclaredField("bootstrapServers");
        bootstrap.setAccessible(true);
        bootstrap.set(config, "localhost:9092");
        Method method = KafkaProducerConfig.class.getDeclaredMethod("baseProducerProps");
        method.setAccessible(true);
        @SuppressWarnings("unchecked")
        Map<String, Object> props = (Map<String, Object>) method.invoke(config);

        assertThat(props.get(ProducerConfig.RETRIES_CONFIG)).isEqualTo(3);
        assertThat(props.get(ProducerConfig.DELIVERY_TIMEOUT_MS_CONFIG)).isEqualTo(10_000);
        assertThat(props.get(ProducerConfig.REQUEST_TIMEOUT_MS_CONFIG)).isEqualTo(3_000);
        assertThat(props.get(ProducerConfig.MAX_BLOCK_MS_CONFIG)).isEqualTo(500);
        assertThat(props.get(ProducerConfig.ACKS_CONFIG)).isEqualTo("all");
        assertThat(props.get(ProducerConfig.ENABLE_IDEMPOTENCE_CONFIG)).isEqualTo(true);
    }
}
