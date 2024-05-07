package com.tutict.finalassignmentbackend.config.vertx;

import io.vertx.core.Vertx;
import io.vertx.kafka.client.consumer.KafkaConsumer;
import org.springframework.boot.autoconfigure.condition.ConditionalOnMissingBean;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class KafkaVerticleAutoConfiguration {

    private final Vertx vertx;

    private final KafkaConsumer<String, String> kafkaConsumer;

    public KafkaVerticleAutoConfiguration(Vertx vertx, KafkaConsumer<String, String> kafkaConsumer) {
        this.vertx = vertx;
        this.kafkaConsumer = kafkaConsumer;
    }

    @Bean(name = "kafkaVerticleConfig")
    @ConditionalOnMissingBean
    public KafkaVerticle kafkaVerticle() {
        return new KafkaVerticle(vertx, kafkaConsumer);
    }
}