package com.tutict.finalassignmentbackend.reliability;

import static org.assertj.core.api.Assertions.assertThat;

import java.time.Duration;
import org.junit.jupiter.api.Test;

class LedgerReliabilityPolicyTest {

    @Test
    void missingHistoryInserts() {
        assertThat(LedgerIdempotencyDecider.decide(false, null, null, "sha256:a", Duration.ZERO))
                .isEqualTo(LedgerIdempotencyDecider.Outcome.INSERT);
    }

    @Test
    void sameFingerprintReplays() {
        assertThat(LedgerIdempotencyDecider.decide(true, "SUCCESS", "sha256:a", "sha256:a", Duration.ofSeconds(1)))
                .isEqualTo(LedgerIdempotencyDecider.Outcome.REPLAY);
    }

    @Test
    void differentFingerprintConflicts() {
        assertThat(LedgerIdempotencyDecider.decide(true, "SUCCESS", "sha256:a", "sha256:b", Duration.ofSeconds(1)))
                .isEqualTo(LedgerIdempotencyDecider.Outcome.CONFLICT);
    }

    @Test
    void legacyDoneReplays() {
        assertThat(LedgerIdempotencyDecider.decide(true, "SUCCESS", "DONE", "sha256:b", Duration.ofSeconds(1)))
                .isEqualTo(LedgerIdempotencyDecider.Outcome.REPLAY);
    }

    @Test
    void freshProcessingIsInProgress() {
        assertThat(LedgerIdempotencyDecider.decide(true, "PROCESSING", "sha256:a", "sha256:a", Duration.ofSeconds(30)))
                .isEqualTo(LedgerIdempotencyDecider.Outcome.IN_PROGRESS);
    }

    @Test
    void staleProcessingAndFailureCanRetry() {
        assertThat(LedgerIdempotencyDecider.decide(true, "PROCESSING", "sha256:a", "sha256:a", Duration.ofMinutes(2)))
                .isEqualTo(LedgerIdempotencyDecider.Outcome.RETRY);
        assertThat(LedgerIdempotencyDecider.decide(true, "FAILED", "boom", "sha256:a", Duration.ofMinutes(5)))
                .isEqualTo(LedgerIdempotencyDecider.Outcome.RETRY);
    }

    @Test
    void shedsNonLedgerGetsBeforeSaturatedLedgerWrites() {
        assertThat(LoadShedPolicy.shed("GET", "/api/auth/me", 0.8, 0, 1)).isTrue();
        assertThat(LoadShedPolicy.shed("GET", "/api/payments/1", 0.9, 0, 0)).isFalse();
        assertThat(LoadShedPolicy.shed("POST", "/api/payments", 0.9, 0, 0)).isTrue();
        assertThat(LoadShedPolicy.shed("POST", "/api/payments", 0.1, 1, 0)).isTrue();
        assertThat(LoadShedPolicy.shed("GET", "/actuator/health", 1.0, 4, 0)).isFalse();
        assertThat(LoadShedPolicy.shedWhenBusy("GET", "/api/auth/me", 33, 32)).isTrue();
        assertThat(LoadShedPolicy.shedWhenBusy("GET", "/api/auth/me", 32, 32)).isFalse();
        assertThat(LoadShedPolicy.shedWhenBusy("GET", "/api/payments", 40, 32)).isFalse();
        assertThat(LoadShedPolicy.shedWhenBusy("POST", "/api/payments", 33, 32)).isTrue();
        assertThat(LoadShedPolicy.shedWhenBusy("GET", "/actuator/health", 100, 32)).isFalse();
    }

    @Test
    void redisOutageShedsWritesAndLoginButAllowsReads() {
        assertThat(BlacklistAccessPolicy.decide("GET", "/api/offenses/1", BlacklistAccessPolicy.Verdict.UNAVAILABLE))
                .isEqualTo(BlacklistAccessPolicy.Effect.ALLOW);
        assertThat(BlacklistAccessPolicy.decide("POST", "/api/payments", BlacklistAccessPolicy.Verdict.UNAVAILABLE))
                .isEqualTo(BlacklistAccessPolicy.Effect.SHED);
        assertThat(BlacklistAccessPolicy.decide("POST", "/api/auth/login", BlacklistAccessPolicy.Verdict.UNAVAILABLE))
                .isEqualTo(BlacklistAccessPolicy.Effect.SHED);
        assertThat(BlacklistAccessPolicy.decide("GET", "/api/offenses/1", BlacklistAccessPolicy.Verdict.REVOKED))
                .isEqualTo(BlacklistAccessPolicy.Effect.DENY);
    }
}
