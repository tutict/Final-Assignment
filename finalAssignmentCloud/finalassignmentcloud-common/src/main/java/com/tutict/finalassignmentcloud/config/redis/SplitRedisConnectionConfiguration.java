package com.tutict.finalassignmentcloud.config.redis;

import java.time.Duration;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.boot.autoconfigure.AutoConfiguration;
import org.springframework.boot.autoconfigure.condition.ConditionalOnClass;
import org.springframework.boot.autoconfigure.condition.ConditionalOnMissingBean;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.boot.data.redis.autoconfigure.DataRedisAutoConfiguration;
import org.springframework.boot.data.redis.autoconfigure.DataRedisProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Primary;
import org.springframework.data.redis.connection.RedisConnectionFactory;
import org.springframework.data.redis.connection.RedisStandaloneConfiguration;
import org.springframework.data.redis.connection.lettuce.LettuceClientConfiguration;
import org.springframework.data.redis.connection.lettuce.LettuceConnectionFactory;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.util.StringUtils;

@AutoConfiguration(before = DataRedisAutoConfiguration.class)
@ConditionalOnClass(LettuceConnectionFactory.class)
@EnableConfigurationProperties(DataRedisProperties.class)
public class SplitRedisConnectionConfiguration {

    @Bean
    @Primary
    @ConditionalOnMissingBean(RedisConnectionFactory.class)
    public RedisConnectionFactory redisConnectionFactory(DataRedisProperties properties) {
        return factory(properties, RedisCommandTimeouts.CACHE);
    }

    @Bean(name = "blacklistRedisConnectionFactory")
    @ConditionalOnMissingBean(name = "blacklistRedisConnectionFactory")
    public RedisConnectionFactory blacklistRedisConnectionFactory(DataRedisProperties properties) {
        return factory(properties, RedisCommandTimeouts.BLACKLIST);
    }

    @Bean
    @ConditionalOnMissingBean(StringRedisTemplate.class)
    public StringRedisTemplate stringRedisTemplate(
            @Qualifier("redisConnectionFactory") RedisConnectionFactory redisConnectionFactory) {
        return new StringRedisTemplate(redisConnectionFactory);
    }

    static RedisConnectionFactory factory(DataRedisProperties properties, Duration commandTimeout) {
        String host = properties == null || !StringUtils.hasText(properties.getHost()) ? "localhost" : properties.getHost();
        int port = properties == null || properties.getPort() <= 0 ? 6379 : properties.getPort();
        RedisStandaloneConfiguration standalone = new RedisStandaloneConfiguration(host, port);
        if (properties != null) {
            standalone.setDatabase(Math.max(properties.getDatabase(), 0));
            if (StringUtils.hasText(properties.getUsername())) {
                standalone.setUsername(properties.getUsername());
            }
            if (StringUtils.hasText(properties.getPassword())) {
                standalone.setPassword(properties.getPassword());
            }
        }
        LettuceClientConfiguration client = LettuceClientConfiguration.builder()
                .commandTimeout(commandTimeout)
                .build();
        LettuceConnectionFactory factory = new LettuceConnectionFactory(standalone, client);
        factory.setShareNativeConnection(true);
        factory.afterPropertiesSet();
        return factory;
    }
}
