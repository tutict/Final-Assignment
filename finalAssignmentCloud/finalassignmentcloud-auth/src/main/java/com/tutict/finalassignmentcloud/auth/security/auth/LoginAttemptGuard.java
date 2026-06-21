package com.tutict.finalassignmentcloud.auth.security.auth;

import com.github.benmanes.caffeine.cache.Cache;
import com.github.benmanes.caffeine.cache.Caffeine;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;

import java.time.Duration;
import java.util.Locale;
import java.util.concurrent.TimeUnit;
import java.util.logging.Level;
import java.util.logging.Logger;

@Service
public class LoginAttemptGuard {

    private static final Logger LOG = Logger.getLogger(LoginAttemptGuard.class.getName());

    private final Cache<String, AttemptState> attempts;
    private final Duration window;
    private final Duration lockDuration;
    private final Duration failurePenaltyBase;
    private final Duration failurePenaltyMax;
    private final int maxAccountAttempts;
    private final int maxIpAttempts;
    private final int failurePenaltyAfter;
    private final int maxConsecutiveFailures;

    public LoginAttemptGuard(
            @Value("${app.security.login.window:PT1M}") Duration window,
            @Value("${app.security.login.lock-duration:PT2M}") Duration lockDuration,
            @Value("${app.security.login.failure-penalty-base:PT0.75S}") Duration failurePenaltyBase,
            @Value("${app.security.login.failure-penalty-max:PT10S}") Duration failurePenaltyMax,
            @Value("${app.security.login.max-account-attempts:8}") int maxAccountAttempts,
            @Value("${app.security.login.max-ip-attempts:40}") int maxIpAttempts,
            @Value("${app.security.login.failure-penalty-after:2}") int failurePenaltyAfter,
            @Value("${app.security.login.max-consecutive-failures:8}") int maxConsecutiveFailures
    ) {
        this.window = positive(window, Duration.ofMinutes(1));
        this.lockDuration = positive(lockDuration, Duration.ofMinutes(2));
        this.failurePenaltyBase = positive(failurePenaltyBase, Duration.ofMillis(750));
        this.failurePenaltyMax = positive(failurePenaltyMax, Duration.ofSeconds(10));
        this.maxAccountAttempts = Math.max(maxAccountAttempts, 1);
        this.maxIpAttempts = Math.max(maxIpAttempts, this.maxAccountAttempts);
        this.failurePenaltyAfter = Math.max(failurePenaltyAfter, 1);
        this.maxConsecutiveFailures = Math.max(maxConsecutiveFailures, this.failurePenaltyAfter);
        Duration ttl = this.window.plus(this.lockDuration).plus(this.failurePenaltyMax);
        this.attempts = Caffeine.newBuilder()
                .expireAfterAccess(ttl.toMillis(), TimeUnit.MILLISECONDS)
                .maximumSize(20_000)
                .recordStats()
                .build();
    }

    public LoginDecision inspect(String username, HttpServletRequest request) {
        String accountKey = accountKey(username, request);
        String ipKey = ipKey(request);
        long now = System.currentTimeMillis();

        LoginDecision accountDecision = inspectKey(accountKey, now, maxAccountAttempts);
        if (!accountDecision.allowed()) {
            return accountDecision;
        }
        LoginDecision ipDecision = inspectKey(ipKey, now, maxIpAttempts);
        if (!ipDecision.allowed()) {
            return ipDecision;
        }
        return new LoginDecision(accountKey, ipKey, true, 0);
    }

    public void recordSuccess(LoginDecision decision) {
        if (decision == null) {
            return;
        }
        attempts.invalidate(decision.accountKey());
    }

    public Duration recordFailureAndDelay(LoginDecision decision) {
        if (decision == null || !StringUtils.hasText(decision.accountKey())) {
            return Duration.ZERO;
        }
        AttemptState state = attempts.get(decision.accountKey(), ignored -> new AttemptState(System.currentTimeMillis()));
        Duration penalty;
        synchronized (state) {
            long now = System.currentTimeMillis();
            state.rotateIfNeeded(now, window);
            state.consecutiveFailures++;
            if (state.consecutiveFailures >= maxConsecutiveFailures) {
                state.lockedUntilMillis = Math.max(state.lockedUntilMillis, now + lockDuration.toMillis());
            }
            penalty = penaltyFor(state.consecutiveFailures);
        }
        sleepPenalty(penalty);
        return penalty;
    }

    private LoginDecision inspectKey(String key, long now, int maxAttempts) {
        AttemptState state = attempts.get(key, ignored -> new AttemptState(now));
        synchronized (state) {
            state.rotateIfNeeded(now, window);
            if (state.lockedUntilMillis > now) {
                return LoginDecision.blocked(key, retryAfterSeconds(state.lockedUntilMillis, now));
            }
            if (state.windowAttempts >= maxAttempts) {
                state.lockedUntilMillis = now + lockDuration.toMillis();
                return LoginDecision.blocked(key, retryAfterSeconds(state.lockedUntilMillis, now));
            }
            state.windowAttempts++;
            return LoginDecision.allowed(key);
        }
    }

    private Duration penaltyFor(int failures) {
        if (failures < failurePenaltyAfter) {
            return Duration.ZERO;
        }
        int exponent = Math.min(failures - failurePenaltyAfter, 5);
        long multiplier = 1L << exponent;
        long millis = Math.min(failurePenaltyBase.toMillis() * multiplier, failurePenaltyMax.toMillis());
        return Duration.ofMillis(millis);
    }

    private void sleepPenalty(Duration penalty) {
        if (penalty == null || penalty.isZero() || penalty.isNegative()) {
            return;
        }
        try {
            Thread.sleep(penalty.toMillis());
        } catch (InterruptedException ex) {
            Thread.currentThread().interrupt();
            LOG.log(Level.FINE, "Login failure penalty interrupted", ex);
        }
    }

    private long retryAfterSeconds(long lockedUntilMillis, long now) {
        return Math.max(1L, (long) Math.ceil((lockedUntilMillis - now) / 1000.0));
    }

    private String accountKey(String username, HttpServletRequest request) {
        String normalizedUser = StringUtils.hasText(username)
                ? username.trim().toLowerCase(Locale.ROOT)
                : "<blank>";
        return "account:" + normalizedUser + "|ip:" + clientIp(request);
    }

    private String ipKey(HttpServletRequest request) {
        return "ip:" + clientIp(request);
    }

    private String clientIp(HttpServletRequest request) {
        if (request == null) {
            return "unknown";
        }
        String forwardedFor = request.getHeader("X-Forwarded-For");
        if (StringUtils.hasText(forwardedFor)) {
            return forwardedFor.split(",", 2)[0].trim();
        }
        String realIp = request.getHeader("X-Real-IP");
        if (StringUtils.hasText(realIp)) {
            return realIp.trim();
        }
        String remoteAddr = request.getRemoteAddr();
        return StringUtils.hasText(remoteAddr) ? remoteAddr : "unknown";
    }

    private Duration positive(Duration value, Duration fallback) {
        return value == null || value.isZero() || value.isNegative() ? fallback : value;
    }

    public record LoginDecision(
            String accountKey,
            String ipKey,
            boolean allowed,
            long retryAfterSeconds
    ) {
        static LoginDecision allowed(String accountKey) {
            return new LoginDecision(accountKey, null, true, 0);
        }

        static LoginDecision blocked(String key, long retryAfterSeconds) {
            return new LoginDecision(key, null, false, retryAfterSeconds);
        }
    }

    private static final class AttemptState {
        private long windowStartedAtMillis;
        private int windowAttempts;
        private int consecutiveFailures;
        private long lockedUntilMillis;

        private AttemptState(long now) {
            this.windowStartedAtMillis = now;
        }

        private void rotateIfNeeded(long now, Duration window) {
            if (now - windowStartedAtMillis >= window.toMillis()) {
                windowStartedAtMillis = now;
                windowAttempts = 0;
            }
        }
    }
}
