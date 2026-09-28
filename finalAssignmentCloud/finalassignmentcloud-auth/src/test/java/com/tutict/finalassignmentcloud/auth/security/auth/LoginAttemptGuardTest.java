package com.tutict.finalassignmentcloud.auth.security.auth;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.time.Duration;
import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockHttpServletRequest;

class LoginAttemptGuardTest {

    @Test
    void accountLocksAtEightAndPublicIpAtForty() {
        LoginAttemptGuard guard = guard();
        MockHttpServletRequest first = request("203.0.113.8");
        for (int i = 0; i < 8; i++) {
            assertTrue(guard.inspect("alice", first).allowed(), "attempt " + i);
        }
        LoginAttemptGuard.LoginDecision locked = guard.inspect("alice", first);
        assertFalse(locked.allowed());
        assertEquals(120L, locked.retryAfterSeconds());

        LoginAttemptGuard addresses = guard();
        for (int i = 0; i < 40; i++) {
            assertTrue(addresses.inspect("user-" + i, request("203.0.113.9")).allowed(), "ip " + i);
        }
        assertFalse(addresses.inspect("user-40", request("203.0.113.9")).allowed());

        LoginAttemptGuard local = guard();
        for (int i = 0; i < 50; i++) {
            assertTrue(local.inspect("local-" + i, request("127.0.0.1")).allowed(), "loop " + i);
        }
    }


    @Test
    void failedAttemptsLockWithoutSleeping() {
        LoginAttemptGuard guard = new LoginAttemptGuard(
                Duration.ofMinutes(1),
                Duration.ofMinutes(2),
                Duration.ofMillis(750),
                Duration.ofSeconds(10),
                8,
                40,
                2,
                8);
        LoginAttemptGuard.LoginDecision decision = guard.inspect("alice", request("203.0.113.8"));
        long started = System.nanoTime();
        for (int i = 0; i < 8; i++) {
            guard.recordFailure(decision);
        }
        assertTrue((System.nanoTime() - started) / 1_000_000L < 300L);
        LoginAttemptGuard.LoginDecision blocked = guard.inspect("alice", request("203.0.113.9"));
        assertFalse(blocked.allowed());
        assertEquals(120L, blocked.retryAfterSeconds());
    }

    private static LoginAttemptGuard guard() {
        return new LoginAttemptGuard(
                Duration.ofMinutes(1),
                Duration.ofMinutes(2),
                Duration.ofMillis(1),
                Duration.ofMillis(1),
                8,
                40,
                100,
                100);
    }

    private static MockHttpServletRequest request(String remote) {
        MockHttpServletRequest request = new MockHttpServletRequest();
        request.setRemoteAddr(remote);
        return request;
    }
}
