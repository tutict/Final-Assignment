package com.tutict.finalassignmentbackend.ai.chat;

import org.junit.jupiter.api.Test;

import java.time.Duration;
import java.util.concurrent.atomic.AtomicBoolean;

import static org.assertj.core.api.Assertions.assertThat;

class AiUserStreamLimiterTest {

    @Test
    void thirdConcurrentStreamIsRejectedAndSecondRunsAfterRelease() {
        AiUserStreamLimiter limiter = new AiUserStreamLimiter();
        AiUserStreamLimiter.Lease first = limiter.tryAdmit("10");
        AiUserStreamLimiter.Lease second = limiter.tryAdmit("10");
        AiUserStreamLimiter.Lease third = limiter.tryAdmit("10");

        assertThat(first.decision()).isEqualTo(AiUserStreamLimiter.Decision.ACCEPT);
        assertThat(second.decision()).isEqualTo(AiUserStreamLimiter.Decision.QUEUE);
        assertThat(third).isNull();

        AtomicBoolean secondGranted = new AtomicBoolean(false);
        second.awaitTurn().subscribe(unused -> secondGranted.set(true));
        assertThat(secondGranted).isFalse();

        first.release();
        second.awaitTurn().block(Duration.ofSeconds(1));
        AiUserStreamLimiter.Lease queued = limiter.tryAdmit("10");
        assertThat(queued.decision()).isEqualTo(AiUserStreamLimiter.Decision.QUEUE);
        assertThat(limiter.tryAdmit("10")).isNull();

        second.release();
        queued.awaitTurn().block(Duration.ofSeconds(1));
        queued.release();
        AiUserStreamLimiter.Lease next = limiter.tryAdmit("10");
        assertThat(next.decision()).isEqualTo(AiUserStreamLimiter.Decision.ACCEPT);
        next.release();
    }

    @Test
    void differentUsersDoNotShareTheSingleFlightSlot() {
        AiUserStreamLimiter limiter = new AiUserStreamLimiter();
        AiUserStreamLimiter.Lease first = limiter.tryAdmit("u1");
        AiUserStreamLimiter.Lease other = limiter.tryAdmit("u2");
        assertThat(first.decision()).isEqualTo(AiUserStreamLimiter.Decision.ACCEPT);
        assertThat(other.decision()).isEqualTo(AiUserStreamLimiter.Decision.ACCEPT);
        first.release();
        other.release();
    }
}
