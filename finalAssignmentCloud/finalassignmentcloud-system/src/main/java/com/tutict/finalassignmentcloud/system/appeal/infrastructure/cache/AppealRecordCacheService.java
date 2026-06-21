package com.tutict.finalassignmentcloud.system.appeal.infrastructure.cache;

import org.springframework.cache.Cache;
import org.springframework.cache.CacheManager;
import org.springframework.stereotype.Service;

@Service
public class AppealRecordCacheService {

    public static final String CACHE_NAME = "appealRecordCache";

    private final CacheManager cacheManager;

    public AppealRecordCacheService(CacheManager cacheManager) {
        this.cacheManager = cacheManager;
    }

    public void evictAll() {
        Cache cache = cacheManager.getCache(CACHE_NAME);
        if (cache != null) {
            cache.clear();
        }
    }
}
