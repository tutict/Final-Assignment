package com.tutict.finalassignmentcloud.reliability;

import static org.junit.jupiter.api.Assertions.assertEquals;

import java.time.Duration;
import org.junit.jupiter.api.Test;

class LedgerIdempotencyDeciderTest {

    private static final String FINGERPRINT_A = LedgerFingerprint.PREFIX + "a".repeat(64);
    private static final String FINGERPRINT_B = LedgerFingerprint.PREFIX + "b".repeat(64);

    @Test
    void newKeyInserts() {
        assertEquals(LedgerIdempotencyDecider.Outcome.INSERT,
                LedgerIdempotencyDecider.decide(false, null, null, FINGERPRINT_A, Duration.ZERO));
    }

    @Test
    void sameKeyAndBodyReplays() {
        assertEquals(LedgerIdempotencyDecider.Outcome.REPLAY,
                LedgerIdempotencyDecider.decide(true, "SUCCESS", FINGERPRINT_A, FINGERPRINT_A, Duration.ofSeconds(1)));
    }

    @Test
    void sameKeyDifferentBodyConflicts() {
        assertEquals(LedgerIdempotencyDecider.Outcome.CONFLICT,
                LedgerIdempotencyDecider.decide(true, "SUCCESS", FINGERPRINT_A, FINGERPRINT_B, Duration.ofSeconds(1)));
    }

    @Test
    void failedHistoryWithSameBodyCanRetry() {
        assertEquals(LedgerIdempotencyDecider.Outcome.RETRY,
                LedgerIdempotencyDecider.decide(true, "FAILED", FINGERPRINT_A, FINGERPRINT_A, Duration.ofMinutes(5)));
    }

    @Test
    void failedHistoryWithDifferentBodyConflicts() {
        assertEquals(LedgerIdempotencyDecider.Outcome.CONFLICT,
                LedgerIdempotencyDecider.decide(true, "FAILED", FINGERPRINT_A, FINGERPRINT_B, Duration.ofMinutes(5)));
    }

    @Test
    void legacyFailureWithoutFingerprintCanRetry() {
        assertEquals(LedgerIdempotencyDecider.Outcome.RETRY,
                LedgerIdempotencyDecider.decide(true, "FAILED", "boom", FINGERPRINT_A, Duration.ofMinutes(5)));
    }

    /**
     * 旧版本在“预留即成功”时写入 PENDING/DONE，没有请求指纹，
     * 无法判断是否同键异内容，只能按已处理对待，避免重复执行副作用。
     */
    @Test
    void legacyReservationMarkerReplays() {
        assertEquals(LedgerIdempotencyDecider.Outcome.REPLAY,
                LedgerIdempotencyDecider.decide(true, "SUCCESS", "PENDING", FINGERPRINT_A, Duration.ofMinutes(5)));
        assertEquals(LedgerIdempotencyDecider.Outcome.REPLAY,
                LedgerIdempotencyDecider.decide(true, "SUCCESS", "DONE", FINGERPRINT_B, Duration.ofMinutes(5)));
        assertEquals(LedgerIdempotencyDecider.Outcome.REPLAY,
                LedgerIdempotencyDecider.decide(true, "SUCCESS", null, FINGERPRINT_B, Duration.ofMinutes(5)));
    }

    @Test
    void processingIsInProgressUntilTwoMinutes() {
        assertEquals(LedgerIdempotencyDecider.Outcome.IN_PROGRESS,
                LedgerIdempotencyDecider.decide(true, "PROCESSING", FINGERPRINT_A, FINGERPRINT_A, Duration.ofSeconds(30)));
        assertEquals(LedgerIdempotencyDecider.Outcome.RETRY,
                LedgerIdempotencyDecider.decide(true, "PROCESSING", FINGERPRINT_A, FINGERPRINT_A, Duration.ofMinutes(2)));
    }
}
