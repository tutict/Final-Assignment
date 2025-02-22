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

    private static final Logger log = Logger.getLogger(RunDocker.class.getName());

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
            log.log(Level.INFO, "Redis container started successfully at {0}:{1}", new Object[]{redisHost, redisPort});
            System.setProperty("spring.data.redis.host", redisHost);
            System.setProperty("spring.data.redis.port", String.valueOf(redisPort));
            log.log(Level.INFO, "Redis properties set: host={0}, port={1}", new Object[]{redisHost, redisPort});
        } catch (Exception e) {
            log.log(Level.SEVERE, "Failed to start Redis container: {0}", new Object[]{e.getMessage()});
            throw new RuntimeException("Redis startup failed", e);
        }
    }

    public void startRedpanda() {
        try {
            redpandaContainer = new RedpandaContainer("redpandadata/redpanda:v24.1.2");
            redpandaContainer.start();
            String bootstrapServers = redpandaContainer.getBootstrapServers();
            log.log(Level.INFO, "Redpanda container started successfully with bootstrap servers: {0}", new Object[]{bootstrapServers});
            System.setProperty("spring.kafka.bootstrap-servers", bootstrapServers);
            log.log(Level.INFO, "Kafka bootstrap-servers set: {0}", new Object[]{bootstrapServers});
        } catch (Exception e) {
            log.log(Level.SEVERE, "Failed to start Redpanda container: {0}", new Object[]{e.getMessage(), e});
            throw new RuntimeException("Redpanda startup failed", e);
        }
    }

    @PreDestroy
    public void stopContainers() {
        if (redisContainer != null && redisContainer.isRunning()) {
            redisContainer.stop();
            log.log(Level.INFO, "Redis container stopped");
        }
        if (redpandaContainer != null && redpandaContainer.isRunning()) {
            redpandaContainer.stop();
            log.log(Level.INFO, "Redpanda container stopped");
        }
    }
}