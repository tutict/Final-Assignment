package com.tutict.finalassignmentcloud.reliability;

import java.time.Duration;

/**
 * 共享台账的幂等决策：只有业务真正成功后才应写入 SUCCESS。
 * PENDING 是旧版本“预留即成功”留下的状态，按可重试处理。
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
            return Outcome.RETRY;
        }
        if ("PROCESSING".equalsIgnoreCase(normalized)) {
            return (age != null && age.compareTo(PROCESSING_TTL) >= 0) ? Outcome.RETRY : Outcome.IN_PROGRESS;
        }
        if ("SUCCESS".equalsIgnoreCase(normalized)) {
            if ("PENDING".equalsIgnoreCase(storedParams)) {
                return Outcome.RETRY;
            }
            return samePayload(storedParams, incomingFingerprint) ? Outcome.REPLAY : Outcome.CONFLICT;
        }
        return Outcome.CONFLICT;
    }

    private static boolean samePayload(String storedParams, String incomingFingerprint) {
        if (incomingFingerprint == null || incomingFingerprint.isBlank()) {
            return true;
        }
        if (storedParams == null || storedParams.isBlank() || "DONE".equalsIgnoreCase(storedParams)) {
            return true;
        }
        return storedParams.equals(incomingFingerprint);
    }
}
