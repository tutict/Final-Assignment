package com.tutict.finalassignmentbackend.config.caffeine;

import com.github.benmanes.caffeine.cache.Caffeine;
import org.springframework.cache.CacheManager;
import org.springframework.cache.annotation.CachingConfigurer;
import org.springframework.cache.annotation.EnableCaching;
import org.springframework.cache.caffeine.CaffeineCacheManager;
import org.springframework.cache.interceptor.CacheErrorHandler;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.TimeUnit;
import java.util.logging.Level;
import java.util.logging.Logger;

@Configuration
@EnableCaching
public class CacheConfig implements CachingConfigurer {

    private static final Logger LOG = Logger.getLogger(CacheConfig.class.getName());

    @Bean(name = "caffeineCacheManager")
    public CacheManager caffeineCacheManager() {
        CaffeineCacheManager cacheManager = new CaffeineCacheManager();
        // 配置 Caffeine 设置
        cacheManager.setCaffeine(Caffeine.newBuilder()
                .expireAfterWrite(5, TimeUnit.MINUTES) // 设置缓存有效期为 5 分钟
                .maximumSize(100) // 每个缓存的最大条目数为 100
                .recordStats()); // 启用缓存统计以便监控
        return cacheManager;
    }

    @Override
    public CacheErrorHandler errorHandler() {
        return new FailOpenCacheErrorHandler();
    }

    private static final class FailOpenCacheErrorHandler implements CacheErrorHandler {
        private final Set<String> warnedFailures = ConcurrentHashMap.newKeySet();

        @Override
        public void handleCacheGetError(RuntimeException exception, org.springframework.cache.Cache cache, Object key) {
            warnOnce("get", exception, cache);
        }

        @Override
        public void handleCachePutError(RuntimeException exception, org.springframework.cache.Cache cache, Object key, Object value) {
            warnOnce("put", exception, cache);
        }

        @Override
        public void handleCacheEvictError(RuntimeException exception, org.springframework.cache.Cache cache, Object key) {
            warnOnce("evict", exception, cache);
        }

        @Override
        public void handleCacheClearError(RuntimeException exception, org.springframework.cache.Cache cache) {
            warnOnce("clear", exception, cache);
        }

        private void warnOnce(String operation, RuntimeException exception, org.springframework.cache.Cache cache) {
            String cacheName = cache != null ? cache.getName() : "unknown";
            String signature = operation + ":" + cacheName + ":" + exception.getClass().getName();
            if (warnedFailures.add(signature)) {
                LOG.log(Level.WARNING,
                        "Cache " + operation + " failed for " + cacheName + "; continuing without cache.",
                        exception);
            }
        }
    }
}
