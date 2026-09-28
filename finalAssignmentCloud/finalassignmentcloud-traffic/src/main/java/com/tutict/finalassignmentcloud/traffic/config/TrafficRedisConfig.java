package com.tutict.finalassignmentcloud.traffic.config;

import com.tutict.finalassignmentcloud.config.redis.RedisCommandTimeouts;
import java.time.Duration;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Primary;
import org.springframework.data.redis.connection.RedisConnectionFactory;
import org.springframework.data.redis.connection.RedisStandaloneConfiguration;
import org.springframework.data.redis.connection.lettuce.LettuceClientConfiguration;
import org.springframework.data.redis.connection.lettuce.LettuceConnectionFactory;

@Configuration
public class TrafficRedisConfig {

    @Value("${spring.data.redis.host:localhost}")
    private String host;

    @Value("${spring.data.redis.port:6379}")
    private int port;

    @Bean
    @Primary
    public RedisConnectionFactory redisConnectionFactory() {
        return factory(RedisCommandTimeouts.CACHE);
    }

    @Bean(name = "blacklistRedisConnectionFactory")
    public RedisConnectionFactory blacklistRedisConnectionFactory() {
        return factory(RedisCommandTimeouts.BLACKLIST);
    }

    private RedisConnectionFactory factory(Duration commandTimeout) {
        RedisStandaloneConfiguration standalone = new RedisStandaloneConfiguration(host, port);
        LettuceClientConfiguration client = LettuceClientConfiguration.builder()
                .commandTimeout(commandTimeout)
                .build();
        LettuceConnectionFactory factory = new LettuceConnectionFactory(standalone, client);
        factory.setShareNativeConnection(true);
        factory.afterPropertiesSet();
        return factory;
    }
}
