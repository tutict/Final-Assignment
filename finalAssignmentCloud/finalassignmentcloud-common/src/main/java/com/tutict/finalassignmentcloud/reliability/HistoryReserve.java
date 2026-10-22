package com.tutict.finalassignmentcloud.reliability;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.core.conditions.update.UpdateWrapper;
import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.tutict.finalassignmentcloud.entity.SysRequestHistory;
import org.springframework.dao.DuplicateKeyException;

import java.time.Duration;
import java.time.LocalDateTime;

/**
 * 在业务执行前预留幂等键（PROCESSING），业务成功后再由调用方标记 SUCCESS。
 * 失败重试和并发重复会得到可区分的异常。
 *
 * <p>并发要点：预留走“先插入、冲突再回读”的路径，避免两个请求同时读到空行；
 * 重试走状态条件的 CAS 更新，避免同一幂等键被两个请求同时执行副作用。
 */
public final class HistoryReserve {

    /** {@code sys_request_history.idempotency_key} 的列宽。 */
    public static final int MAX_KEY_LENGTH = 64;

    private HistoryReserve() {
    }

    public static void reserve(BaseMapper<SysRequestHistory> mapper,
                               String key,
                               String businessType,
                               String fingerprint) {
        if (key == null || key.isBlank()) {
            throw new IllegalArgumentException("Idempotency-Key must not be blank");
        }
        String normalizedKey = normalizeKey(key);
        SysRequestHistory existing = find(mapper, normalizedKey);
        if (existing != null) {
            applyExisting(mapper, existing, normalizedKey, businessType, fingerprint);
            return;
        }
        SysRequestHistory created = new SysRequestHistory();
        created.setIdempotencyKey(normalizedKey);
        created.setBusinessStatus("PROCESSING");
        created.setBusinessType(businessType);
        created.setRequestParams(fingerprint);
        created.setCreatedAt(LocalDateTime.now());
        created.setUpdatedAt(LocalDateTime.now());
        try {
            mapper.insert(created);
        } catch (DuplicateKeyException ex) {
            // 唯一键冲突说明并发请求已经写入了同一个幂等键，这里必须用加锁读（当前读）回读：
            // 可重复读隔离级别下的一致读看不到并发事务提交后的行，只会拿到最初的快照。
            SysRequestHistory concurrent = findForUpdate(mapper, normalizedKey);
            if (concurrent == null) {
                throw ex;
            }
            applyExisting(mapper, concurrent, normalizedKey, businessType, fingerprint);
        }
    }

    /**
     * 标记业务成功。只允许从 PROCESSING 迁移，且保留 request_params 中的请求指纹，
     * 否则同键异内容无法再被识别为冲突。
     */
    public static boolean markSuccess(BaseMapper<SysRequestHistory> mapper, String key, Long businessId) {
        UpdateWrapper<SysRequestHistory> update = new UpdateWrapper<SysRequestHistory>()
                .eq("idempotency_key", normalizeKey(key))
                .eq("business_status", "PROCESSING")
                .set("business_status", "SUCCESS")
                .set("business_id", businessId)
                .set("updated_at", LocalDateTime.now());
        return mapper.update(null, update) > 0;
    }

    /**
     * 标记业务失败。只允许从 PROCESSING 迁移，同样保留请求指纹以便重试时识别同键异内容。
     */
    public static boolean markFailure(BaseMapper<SysRequestHistory> mapper, String key) {
        UpdateWrapper<SysRequestHistory> update = new UpdateWrapper<SysRequestHistory>()
                .eq("idempotency_key", normalizeKey(key))
                .eq("business_status", "PROCESSING")
                .set("business_status", "FAILED")
                .set("updated_at", LocalDateTime.now());
        return mapper.update(null, update) > 0;
    }

    private static void applyExisting(BaseMapper<SysRequestHistory> mapper,
                                      SysRequestHistory existing,
                                      String key,
                                      String businessType,
                                      String fingerprint) {
        LocalDateTime stamp = existing.getUpdatedAt() != null ? existing.getUpdatedAt() : existing.getCreatedAt();
        Duration age = stamp == null ? Duration.ZERO : Duration.between(stamp, LocalDateTime.now());
        switch (LedgerIdempotencyDecider.decide(
                true, existing.getBusinessStatus(), existing.getRequestParams(), fingerprint, age)) {
            case REPLAY -> throw new IdempotencyReplayException("Duplicate request for idempotency key " + key);
            case CONFLICT -> throw new IdempotencyConflictException(
                    "Idempotency key " + key + " was reused with a different request payload");
            case IN_PROGRESS -> throw new IdempotencyInProgressException(
                    "Idempotency key " + key + " is already being processed");
            case RETRY -> retry(mapper, existing, key, businessType, fingerprint);
            default -> throw new IllegalStateException("Unexpected idempotency outcome");
        }
    }

    /**
     * 重试只允许在原状态未变时接管：CAS 条件失败说明另一个请求已经接管或完成了该幂等键。
     */
    private static void retry(BaseMapper<SysRequestHistory> mapper,
                              SysRequestHistory existing,
                              String key,
                              String businessType,
                              String fingerprint) {
        String observedStatus = existing.getBusinessStatus();
        UpdateWrapper<SysRequestHistory> update = new UpdateWrapper<SysRequestHistory>()
                .eq("idempotency_key", key)
                .eq("business_status", observedStatus)
                .set("business_status", "PROCESSING")
                .set("business_type", businessType)
                .set("request_params", fingerprint)
                .set("updated_at", LocalDateTime.now());
        if (existing.getUpdatedAt() == null) {
            update.isNull("updated_at");
        } else {
            update.eq("updated_at", existing.getUpdatedAt());
        }
        if (mapper.update(null, update) == 0) {
            throw new IdempotencyInProgressException(
                    "Idempotency key is being retried concurrently: " + key);
        }
    }

    private static SysRequestHistory find(BaseMapper<SysRequestHistory> mapper, String key) {
        return mapper.selectOne(new QueryWrapper<SysRequestHistory>()
                .eq("idempotency_key", key)
                .last("LIMIT 1"));
    }

    /**
     * 加锁读（当前读）：读取最新已提交的行，而不是事务快照里的旧版本。
     */
    private static SysRequestHistory findForUpdate(BaseMapper<SysRequestHistory> mapper, String key) {
        return mapper.selectOne(new QueryWrapper<SysRequestHistory>()
                .eq("idempotency_key", key)
                .last("LIMIT 1 FOR UPDATE"));
    }

    /**
     * 超长幂等键统一收敛为摘要，保证与唯一索引列宽一致且重放稳定。
     */
    public static String normalizeKey(String key) {
        String trimmed = key.trim();
        if (trimmed.length() <= MAX_KEY_LENGTH) {
            return trimmed;
        }
        return LedgerFingerprint.sha256(trimmed);
    }
}
