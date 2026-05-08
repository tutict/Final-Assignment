package com.tutict.finalassignmentbackend.appeal.cache;

import com.tutict.finalassignmentbackend.appeal.infrastructure.cache.AppealRecordCacheService;
import com.tutict.finalassignmentbackend.appeal.infrastructure.transaction.AfterCommitExecutor;
import org.springframework.stereotype.Service;

import java.util.Collection;

@Service
public class AppealCachePolicy {

    public enum Region {
        DETAIL,
        QUERY,
        LIST
    }

    public enum EvictionStrategy {
        ON_WRITE_AFTER_COMMIT,
        MANUAL
    }

    public static final String CACHE_NAME = AppealRecordCacheService.CACHE_NAME;

    private final AppealRecordCacheService cacheService;
    private final AfterCommitExecutor afterCommitExecutor;
    private final ThreadLocal<Boolean> skipNextCachePut = ThreadLocal.withInitial(() -> false);

    public AppealCachePolicy(
            AppealRecordCacheService cacheService,
            AfterCommitExecutor afterCommitExecutor
    ) {
        this.cacheService = cacheService;
        this.afterCommitExecutor = afterCommitExecutor;
    }

    public void onWrite() {
        afterCommitExecutor.execute(cacheService::evictAll);
    }

    public void markFallbackRead() {
        skipNextCachePut.set(true);
    }

    public boolean shouldSkipCache(Object result) {
        try {
            return skipNextCachePut.get()
                    || result == null
                    || (result instanceof Collection<?> collection && collection.isEmpty());
        } finally {
            skipNextCachePut.remove();
        }
    }

    public Object detailKey(Long appealId) {
        return appealId;
    }

    public String queryKey(String queryName, Object... parts) {
        StringBuilder key = new StringBuilder(queryName);
        if (parts == null) {
            return key.toString();
        }
        for (Object part : parts) {
            key.append(':').append(part);
        }
        return key.toString();
    }

    public Region detailRegion() {
        return Region.DETAIL;
    }

    public Region queryRegion() {
        return Region.QUERY;
    }

    public Region listRegion() {
        return Region.LIST;
    }

    public EvictionStrategy writeEvictionStrategy() {
        return EvictionStrategy.ON_WRITE_AFTER_COMMIT;
    }
}
