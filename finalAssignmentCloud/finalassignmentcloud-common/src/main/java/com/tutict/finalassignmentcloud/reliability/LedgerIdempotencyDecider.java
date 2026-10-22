package com.tutict.finalassignmentcloud.reliability;

import java.time.Duration;

/**
 * 共享台账的幂等决策：只有业务真正成功后才应写入 SUCCESS。
 * PENDING / DONE 是旧版本“预留即成功”留下的占位值，没有请求指纹，无法判断是否同键异内容，
 * 只能按“已处理”对待，避免重复执行副作用。
 */
public final class LedgerIdempotencyDecider {

    public static final Duration PROCESSING_TTL = Duration.ofMinutes(2);

    public enum Outcome {
        INSERT, REPLAY, CONFLICT, IN_PROGRESS, RETRY
    }

    private LedgerIdempotencyDecider() {
    }

    public static Outcome decide(boolean exists, String status, String storedParams, String incomingFingerprint, Duration age) {
        if (!exists) {
            return Outcome.INSERT;
        }
        String normalized = status == null ? "" : status.trim();
        if ("FAILED".equalsIgnoreCase(normalized)) {
            if (!LedgerFingerprint.isFingerprint(storedParams)) {
                return Outcome.RETRY;
            }
            return sameFingerprint(storedParams, incomingFingerprint) ? Outcome.RETRY : Outcome.CONFLICT;
        }
        if ("PROCESSING".equalsIgnoreCase(normalized)) {
            return (age != null && age.compareTo(PROCESSING_TTL) >= 0) ? Outcome.RETRY : Outcome.IN_PROGRESS;
        }
        if ("SUCCESS".equalsIgnoreCase(normalized)) {
            if (!LedgerFingerprint.isFingerprint(storedParams)) {
                return Outcome.REPLAY;
            }
            return sameFingerprint(storedParams, incomingFingerprint) ? Outcome.REPLAY : Outcome.CONFLICT;
        }
        return Outcome.CONFLICT;
    }

    private static boolean sameFingerprint(String storedParams, String incomingFingerprint) {
        if (incomingFingerprint == null || incomingFingerprint.isBlank()) {
            return true;
        }
        return storedParams.equals(incomingFingerprint);
    }
}
