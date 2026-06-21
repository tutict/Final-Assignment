package com.tutict.finalassignmentcloud.system.appeal.infrastructure.cache;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.cache.Cache;
import org.springframework.cache.CacheManager;
import org.springframework.stereotype.Service;

/**
 * Appeal Record Cache Service
 * Manages caching operations for appeal records
 */
@Service
public class AppealRecordCacheService {

    private static final Logger log = LoggerFactory.getLogger(AppealRecordCacheService.class);

    public static final String CACHE_NAME = "appealRecordCache";

    private final CacheManager cacheManager;

    public AppealRecordCacheService(CacheManager cacheManager) {
        this.cacheManager = cacheManager;
        log.info("AppealRecordCacheService initialized with cache manager: {}",
                cacheManager.getClass().getSimpleName());
    }

    public void evictAll() {
        log.info("Evicting all entries from appeal cache: {}", CACHE_NAME);

        Cache cache = cacheManager.getCache(CACHE_NAME);
        if (cache != null) {
            cache.clear();
            log.info("Successfully cleared appeal cache: {}", CACHE_NAME);
        } else {
            log.warn("Cache not found, skipping eviction: {}", CACHE_NAME);
        }
    }

    public void evict(Long appealId) {
        log.debug("Evicting appeal from cache: appealId={}", appealId);

        Cache cache = cacheManager.getCache(CACHE_NAME);
        if (cache != null) {
            cache.evict(appealId);
            log.info("Successfully evicted appeal from cache: appealId={}", appealId);
        } else {
            log.warn("Cache not found, skipping eviction: cache={}, appealId={}", CACHE_NAME, appealId);
        }
    }
}
