package com.tutict.finalassignmentbackend.config;

import io.vertx.core.Vertx;
import io.vertx.kafka.client.consumer.KafkaConsumer;
import org.apache.kafka.clients.consumer.ConsumerConfig;
import org.apache.kafka.common.serialization.StringDeserializer;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.DependsOn;

import java.util.HashMap;
import java.util.Map;
import java.util.Properties;

// 配置类，用于设置Kafka的相关配置
@Configuration
public class KafkaConfig {

    // 从应用属性文件中注入Kafka bootstrap服务器地址
    @Value("${spring.kafka.bootstrap-servers}")
    private String bootstrapServers;

    /**
     * 创建Kafka消费者Bean
     *
     * @param vertx Vert.x实例，用于创建Kafka消费者
     * @return 返回配置好的Kafka消费者实例
     * {@code @DependsOn("vertx")} 表示该方法依赖于'vertx' Bean，确保在执行前'vertx' Bean已经被创建
     */
    @Bean
    @DependsOn("vertx") // 确保Vertx Bean已经存在
    public KafkaConsumer<String, String> kafkaConsumer(Vertx vertx) {
        // 使用Map代替Properties以便更现代化的配置
        Map<String, String> config = new HashMap<>();
        config.put(ConsumerConfig.BOOTSTRAP_SERVERS_CONFIG, bootstrapServers); // 设置bootstrap服务器地址
        config.put(ConsumerConfig.GROUP_ID_CONFIG, "my-group"); // 设置消费者组ID
        config.put(ConsumerConfig.KEY_DESERIALIZER_CLASS_CONFIG, StringDeserializer.class.getName()); // 设置键的反序列化器
        config.put(ConsumerConfig.VALUE_DESERIALIZER_CLASS_CONFIG, StringDeserializer.class.getName()); // 设置值的反序列化器
        config.put(ConsumerConfig.AUTO_OFFSET_RESET_CONFIG, "earliest"); // 设置消费者从最早的数据开始消费

        // 使用Vert.x的KafkaConsumer创建方法，创建并返回Kafka消费者实例
        return KafkaConsumer.create(vertx, config, String.class, String.class);
    }
}
