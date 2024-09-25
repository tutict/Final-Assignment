package com.tutict.finalassignmentbackend.config;

import io.vertx.core.Vertx;
import io.vertx.kafka.client.consumer.KafkaConsumer;
import org.apache.kafka.common.serialization.StringDeserializer;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.DependsOn;

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
        // 初始化Kafka消费者属性
        Properties props = new Properties();
        props.put("bootstrap.servers", bootstrapServers); // 设置bootstrap服务器地址
        props.put("group.id", "my-group"); // 设置消费者组ID
        props.put("key.deserializer", StringDeserializer.class.getName()); // 设置键的反序列化器
        props.put("value.deserializer", StringDeserializer.class.getName()); // 设置值的反序列化器

        // 使用Vert.x的KafkaConsumer创建方法，创建并返回Kafka消费者实例
        return KafkaConsumer.create(vertx, props, String.class, String.class);
    }
}
