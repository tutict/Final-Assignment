package com.tutict.finalassignmentcloud.config.redis;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.time.Duration;
import org.junit.jupiter.api.Test;
import org.springframework.boot.autoconfigure.AutoConfigurations;
import org.springframework.boot.data.redis.autoconfigure.DataRedisAutoConfiguration;
import org.springframework.boot.data.redis.autoconfigure.DataRedisProperties;
import org.springframework.boot.test.context.runner.ApplicationContextRunner;
import org.springframework.data.redis.connection.RedisConnectionFactory;
import org.springframework.data.redis.connection.lettuce.LettuceConnectionFactory;
import org.springframework.data.redis.core.StringRedisTemplate;

class SplitRedisConnectionConfigurationTest {

    private final ApplicationContextRunner runner = new ApplicationContextRunner()
            .withConfiguration(AutoConfigurations.of(
                    SplitRedisConnectionConfiguration.class,
                    DataRedisAutoConfiguration.class))
            .withPropertyValues(
                    "spring.data.redis.host=127.0.0.1",
                    "spring.data.redis.port=6379",
                    "spring.data.redis.timeout=200ms");

    @Test
    void cacheIs300msAndBlacklistIs200ms() {
        DataRedisProperties properties = new DataRedisProperties();
        properties.setHost("127.0.0.1");
        properties.setPort(6379);
        properties.setDatabase(0);
        LettuceConnectionFactory cache = (LettuceConnectionFactory) SplitRedisConnectionConfiguration.factory(properties, RedisCommandTimeouts.CACHE);
        LettuceConnectionFactory blacklist = (LettuceConnectionFactory) SplitRedisConnectionConfiguration.factory(properties, RedisCommandTimeouts.BLACKLIST);
        try {
            assertEquals(Duration.ofMillis(300), cache.getClientConfiguration().getCommandTimeout());
            assertEquals(Duration.ofMillis(200), blacklist.getClientConfiguration().getCommandTimeout());
            assertEquals("127.0.0.1", cache.getHostName());
            assertEquals(6379, blacklist.getPort());
        } finally {
            cache.destroy();
            blacklist.destroy();
        }
    }

    @Test
    void autoConfigurationReplacesTheSharedBootClient() {
        runner.run(context -> {
            assertTrue(context.getStartupFailure() == null, String.valueOf(context.getStartupFailure()));
            LettuceConnectionFactory cache = context.getBean("redisConnectionFactory", LettuceConnectionFactory.class);
            LettuceConnectionFactory blacklist = context.getBean("blacklistRedisConnectionFactory", LettuceConnectionFactory.class);
            assertEquals(Duration.ofMillis(300), cache.getClientConfiguration().getCommandTimeout());
            assertEquals(Duration.ofMillis(200), blacklist.getClientConfiguration().getCommandTimeout());
            StringRedisTemplate template = context.getBean(StringRedisTemplate.class);
            assertTrue(template.getConnectionFactory() instanceof LettuceConnectionFactory);
            assertEquals(Duration.ofMillis(300), ((LettuceConnectionFactory) template.getConnectionFactory()).getClientConfiguration().getCommandTimeout());
            assertEquals(2, context.getBeansOfType(RedisConnectionFactory.class).size());
        });
    }
}
