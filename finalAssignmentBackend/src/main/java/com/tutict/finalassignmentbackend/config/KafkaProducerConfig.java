package com.tutict.finalassignmentbackend.config;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentbackend.entity.DeductionRecord;
import com.tutict.finalassignmentbackend.entity.VehicleInformation;
import org.apache.kafka.clients.producer.ProducerConfig;
import org.apache.kafka.common.serialization.StringSerializer;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Primary;
import org.springframework.kafka.core.DefaultKafkaProducerFactory;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.kafka.core.ProducerFactory;

import java.util.HashMap;
import java.util.Map;

@Configuration
public class KafkaProducerConfig {

    @Value("${spring.kafka.bootstrap-servers}")
    private String bootstrapServers;

    private Map<String, Object> baseProducerProps() {
        Map<String, Object> props = new HashMap<>();
        props.put(ProducerConfig.BOOTSTRAP_SERVERS_CONFIG, bootstrapServers);
        props.put(ProducerConfig.KEY_SERIALIZER_CLASS_CONFIG, StringSerializer.class);
        return props;
    }

    @Bean
    public ProducerFactory<String, String> stringProducerFactory() {
        Map<String, Object> props = baseProducerProps();
        props.put(ProducerConfig.VALUE_SERIALIZER_CLASS_CONFIG, StringSerializer.class);
        return new DefaultKafkaProducerFactory<>(props);
    }

    @Bean
    @Primary
    public KafkaTemplate<String, String> kafkaTemplate(ProducerFactory<String, String> stringProducerFactory) {
        return new KafkaTemplate<>(stringProducerFactory);
    }

    @Bean
    public ProducerFactory<String, VehicleInformation> vehicleInformationProducerFactory(ObjectMapper objectMapper) {
        Map<String, Object> props = baseProducerProps();
        return new DefaultKafkaProducerFactory<>(
                props,
                new StringSerializer(),
                new JacksonKafkaSerializer<>(objectMapper)
        );
    }

    @Bean
    public KafkaTemplate<String, VehicleInformation> vehicleInformationKafkaTemplate(
            ProducerFactory<String, VehicleInformation> vehicleInformationProducerFactory) {
        return new KafkaTemplate<>(vehicleInformationProducerFactory);
    }

    @Bean
    public ProducerFactory<String, DeductionRecord> deductionRecordProducerFactory(ObjectMapper objectMapper) {
        Map<String, Object> props = baseProducerProps();
        return new DefaultKafkaProducerFactory<>(
                props,
                new StringSerializer(),
                new JacksonKafkaSerializer<>(objectMapper)
        );
    }

    @Bean
    public KafkaTemplate<String, DeductionRecord> deductionRecordKafkaTemplate(
            ProducerFactory<String, DeductionRecord> deductionRecordProducerFactory) {
        return new KafkaTemplate<>(deductionRecordProducerFactory);
    }
}
