package com.tutict.finalassignmentcloud.traffic.reliability;

import static org.junit.jupiter.api.Assertions.assertEquals;

import java.time.Duration;
import org.junit.jupiter.api.Test;

class LedgerIdempotencyDeciderTest {

    @Test
    void newKeyInserts() {
        assertEquals(LedgerIdempotencyDecider.Outcome.INSERT,
                LedgerIdempotencyDecider.decide(false, null, null, "sha256:a", Duration.ZERO));
    }

    @Test
    void sameKeyAndBodyReplays() {
        assertEquals(LedgerIdempotencyDecider.Outcome.REPLAY,
                LedgerIdempotencyDecider.decide(true, "SUCCESS", "sha256:a", "sha256:a", Duration.ofSeconds(1)));
    }

    @Test
    void sameKeyDifferentBodyConflicts() {
        assertEquals(LedgerIdempotencyDecider.Outcome.CONFLICT,
                LedgerIdempotencyDecider.decide(true, "SUCCESS", "sha256:a", "sha256:b", Duration.ofSeconds(1)));
    }

    @Test
    void failedHistoryCanRetry() {
        assertEquals(LedgerIdempotencyDecider.Outcome.RETRY,
                LedgerIdempotencyDecider.decide(true, "FAILED", "boom", "sha256:a", Duration.ofMinutes(5)));
    }

    @Test
    void processingIsInProgressUntilTwoMinutes() {
        assertEquals(LedgerIdempotencyDecider.Outcome.IN_PROGRESS,
                LedgerIdempotencyDecider.decide(true, "PROCESSING", "sha256:a", "sha256:a", Duration.ofSeconds(30)));
        assertEquals(LedgerIdempotencyDecider.Outcome.RETRY,
                LedgerIdempotencyDecider.decide(true, "PROCESSING", "sha256:a", "sha256:a", Duration.ofMinutes(2)));
    }
}