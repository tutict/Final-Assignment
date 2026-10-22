package com.tutict.finalassignmentcloud.reliability;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.tutict.finalassignmentcloud.entity.SysRequestHistory;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.time.Duration;
import java.time.LocalDateTime;

/**
 * 在业务执行前预留幂等键（PROCESSING），业务成功后再由调用方标记 SUCCESS。
 * 失败重试和并发重复会得到可区分的异常。
 */
public final class HistoryReserve {

    private HistoryReserve() {
    }

    public static void reserve(BaseMapper<SysRequestHistory> mapper,
                               String key,
                               String businessType,
                               String fingerprint) {
        if (key == null || key.isBlank()) {
            throw new IllegalArgumentException("Idempotency-Key must not be blank");
        }
        SysRequestHistory history = mapper.selectOne(new QueryWrapper<SysRequestHistory>()
                .eq("idempotency_key", key)
                .last("LIMIT 1"));
        if (history == null) {
            SysRequestHistory created = new SysRequestHistory();
            created.setIdempotencyKey(key);
            created.setBusinessStatus("PROCESSING");
            created.setBusinessType(businessType);
            created.setRequestParams(fingerprint);
            created.setCreatedAt(LocalDateTime.now());
            created.setUpdatedAt(LocalDateTime.now());
            mapper.insert(created);
            return;
        }
        LocalDateTime stamp = history.getUpdatedAt() != null ? history.getUpdatedAt() : history.getCreatedAt();
        Duration age = stamp == null ? Duration.ZERO : Duration.between(stamp, LocalDateTime.now());
        switch (LedgerIdempotencyDecider.decide(
                true, history.getBusinessStatus(), history.getRequestParams(), fingerprint, age)) {
            case REPLAY -> throw new IdempotencyReplayException();
            case CONFLICT -> throw new IdempotencyConflictException();
            case IN_PROGRESS -> throw new IdempotencyInProgressException();
            case RETRY -> {
                history.setBusinessStatus("PROCESSING");
                history.setBusinessType(businessType);
                history.setRequestParams(fingerprint);
                history.setUpdatedAt(LocalDateTime.now());
                mapper.updateById(history);
            }
            default -> throw new IllegalStateException("Unexpected idempotency outcome");
        }
    }

    public static String sha256(String canonical) {
        try {
            byte[] hash = MessageDigest.getInstance("SHA-256")
                    .digest(canonical.getBytes(StandardCharsets.UTF_8));
            return "sha256:" + java.util.HexFormat.of().formatHex(hash);
        } catch (NoSuchAlgorithmException ex) {
            throw new IllegalStateException(ex);
        }
    }
}
