package com.tutict.finalassignmentbackend.config.docker;

import com.redis.testcontainers.RedisContainer;
import jakarta.annotation.PostConstruct;
import jakarta.annotation.PreDestroy;
import org.springframework.stereotype.Component;
import org.testcontainers.redpanda.RedpandaContainer;

import java.util.logging.Level;
import java.util.logging.Logger;

@Component
public class RunDocker {

    private final Logger log = Logger.getLogger(RunDocker.class.getName());

    // 保存容器实例作为类的字段
    private RedisContainer redisContainer;

    private RedpandaContainer redpandaContainer;

    @PostConstruct
    public void init() {
        startRedis();
        startRedpanda();
    }

    public void startRedis() {
        try {
            redisContainer = new RedisContainer("redis:7");
            redisContainer.start();
            String redisHost = redisContainer.getHost();
            int redisPort = redisContainer.getFirstMappedPort();
            log.log(Level.INFO, "Redis container started successfully at {}", redisPort);

            // 动态设置 Redis 配置
            System.setProperty("spring.data.redis.host", redisHost);
            System.setProperty("spring.data.redis.port", String.valueOf(redisPort));
        } catch (Exception e) {
            log.log(Level.WARNING, "Redis docker-image connection failed: " + e.getMessage());
        }
    }

    public void startRedpanda() {
        try {
            redpandaContainer = new RedpandaContainer("redpandadata/redpanda:v24.1.2");
            redpandaContainer.start();
            String bootstrapServers = redpandaContainer.getBootstrapServers();
            log.log(Level.INFO, "Redpanda container started successfully with bootstrap servers: " + bootstrapServers);

            // 动态设置 spring.kafka.bootstrap-servers 属性
            System.setProperty("spring.kafka.bootstrap-servers", bootstrapServers);
        } catch (Exception e) {
            log.log(Level.WARNING, "Redpanda docker-image connection failed: " + e.getMessage());
        }
    }

    // 在应用程序关闭时停止容器
    @PreDestroy
    public void stopContainers() {
        if (redisContainer != null) {
            redisContainer.stop();
            log.log(Level.INFO, "Redis container stopped");
        }
        if (redpandaContainer != null) {
            redpandaContainer.stop();
            log.log(Level.INFO, "Kafka container stopped");
        }
    }
}