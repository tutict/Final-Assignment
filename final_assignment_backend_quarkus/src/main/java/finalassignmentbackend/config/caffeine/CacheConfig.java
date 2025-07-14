package finalassignmentbackend.config.caffeine;

import com.github.benmanes.caffeine.cache.Caffeine;
import io.quarkus.cache.Cache;
import io.quarkus.cache.CaffeineCache;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.enterprise.inject.Produces;
import jakarta.inject.Named;

import java.util.concurrent.TimeUnit;
import java.util.logging.Level;
import java.util.logging.Logger;

// Quarkus配置类，用于设置Caffeine缓存
@ApplicationScoped
public class CacheConfig {

    // 日志记录器，用于记录缓存配置过程中的信息
    private static final Logger log = Logger.getLogger(CacheConfig.class.getName());

    // 创建并配置Caffeine缓存
    @Produces
    @Named("caffeineCache")
    @ApplicationScoped
    public Cache caffeineCache() {
        log.log(Level.INFO, "初始化Caffeine缓存，最大条目数为100，过期时间为5分钟");

        // 配置Caffeine缓存
        Caffeine<Object, Object> caffeine = Caffeine.newBuilder()
                .expireAfterWrite(5, TimeUnit.MINUTES) // 设置缓存有效期为5分钟
                .maximumSize(100) // 每个缓存的最大条目数为100
                .recordStats(); // 启用缓存统计以便监控

        // 创建并返回Quarkus的CaffeineCache实例
        Cache cache = new CaffeineCache("caffeineCache", caffeine.build());
        log.log(Level.INFO, "Caffeine缓存初始化成功: {0}", cache.getName());
        return cache;
    }
}