package com.tutict.finalassignmentbackend.config.vertx;

import io.vertx.core.AbstractVerticle;
import io.vertx.core.AsyncResult;
import io.vertx.core.Promise;
import io.vertx.core.Vertx;
import io.vertx.kafka.client.common.TopicPartition;
import io.vertx.kafka.client.consumer.KafkaConsumer;
import org.springframework.beans.factory.annotation.Autowired;

public class KafkaVerticle extends AbstractVerticle {

    private final KafkaConsumer<String, String> kafkaConsumer;

    // 构造函数注入Vertx和KafkaConsumer的实例
    @Autowired
    public KafkaVerticle(Vertx vertx, KafkaConsumer<String, String> kafkaConsumer) {
        this.kafkaConsumer = kafkaConsumer;
    }

    @Override
    public void start(Promise<Void> startPromise) {
        kafkaConsumer.handler(record -> {
            // 处理消息
            System.out.println("Received: " + record.value());
            // 确认消息
            // 消息确认成功
            kafkaConsumer.committed((TopicPartition) record, AsyncResult::succeeded);
        });

        kafkaConsumer.subscribe("my-topic").onComplete(ar -> {
            if (ar.succeeded()) {
                System.out.println("Subscribed to topic my-topic");
                startPromise.complete();
            } else {
                System.out.println("Failed to subscribe to topic my-topic");
                startPromise.fail(ar.cause());
            }
        });
    }
}