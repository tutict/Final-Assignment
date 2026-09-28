package com.tutict.finalassignmentbackend.security.auth;

import static org.assertj.core.api.Assertions.assertThat;

import java.time.Duration;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockHttpServletRequest;

class LoginAttemptGuardTest {

    @Test
    void accountLimitIsIndependentOfAddressAndIgnoresForwardedHeader() {
        LoginAttemptGuard guard = guard();
        for (int i = 0; i < 8; i++) {
            LoginAttemptGuard.LoginDecision decision = guard.inspect("Admin", request("203.0.113." + i));
            assertThat(decision.allowed()).isTrue();
            assertThat(decision.accountKey()).isEqualTo("account:admin");
        }
        LoginAttemptGuard.LoginDecision blocked = guard.inspect("admin", request("203.0.113.50"));
        assertThat(blocked.allowed()).isFalse();
        assertThat(blocked.retryAfterSeconds()).isBetween(119L, 120L);
    }

    @Test
    void oneAddressLocksAtFortyAccounts() {
        LoginAttemptGuard guard = guard();
        for (int i = 0; i < 40; i++) {
            assertThat(guard.inspect("user" + i, request("203.0.113.8")).allowed()).isTrue();
        }
        assertThat(guard.inspect("another", request("203.0.113.8")).allowed()).isFalse();
    }


    @Test
    void failedAttemptsLockWithoutSleeping() {
        LoginAttemptGuard guard = guard();
        LoginAttemptGuard.LoginDecision decision = guard.inspect("admin", request("203.0.113.10"));
        long started = System.nanoTime();
        for (int i = 0; i < 8; i++) {
            guard.recordFailure(decision);
        }
        assertThat((System.nanoTime() - started) / 1_000_000L).isLessThan(300L);
        LoginAttemptGuard.LoginDecision blocked = guard.inspect("admin", request("198.51.100.10"));
        assertThat(blocked.allowed()).isFalse();
        assertThat(blocked.retryAfterSeconds()).isBetween(119L, 120L);
    }

    private static LoginAttemptGuard guard() {
        return new LoginAttemptGuard(
                Duration.ofMinutes(1),
                Duration.ofMinutes(2),
                Duration.ofMillis(750),
                Duration.ofSeconds(10),
                8,
                40,
                2,
                8,
                List.of());
    }

    private static MockHttpServletRequest request(String remoteAddress) {
        MockHttpServletRequest request = new MockHttpServletRequest("POST", "/api/auth/login");
        request.setRemoteAddr(remoteAddress);
        request.addHeader("X-Forwarded-For", "198.51.100.20");
        return request;
    }
}