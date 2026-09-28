package finalassignmentbackend.service.auth;

import jakarta.enterprise.context.ApplicationScoped;

import java.util.ArrayDeque;
import java.util.Deque;
import java.util.Locale;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

@ApplicationScoped
public class LoginAttemptLimiter {

    static final int MAX_ACCOUNT_PER_MINUTE = 8;
    static final int MAX_IP_PER_MINUTE = 40;
    static final long LOCK_MILLIS = 120_000L;

    private final Map<String, Window> accounts = new ConcurrentHashMap<>();
    private final Map<String, Window> ips = new ConcurrentHashMap<>();

    public long reserve(String username, String remoteIp) {
        String normalizedUser = username == null ? "" : username.trim().toLowerCase(Locale.ROOT);
        String ip = remoteIp == null || remoteIp.isBlank() ? "unknown" : remoteIp;
        if (!normalizedUser.isBlank()) {
            long accountRetry = reserve(accounts, "account:" + normalizedUser, MAX_ACCOUNT_PER_MINUTE);
            if (accountRetry > 0) {
                return accountRetry;
            }
        }
        return reserve(ips, "ip:" + ip, MAX_IP_PER_MINUTE);
    }

    private long reserve(Map<String, Window> buckets, String key, int limit) {
        long now = System.currentTimeMillis();
        Window window = buckets.computeIfAbsent(key, ignored -> new Window());
        synchronized (window) {
            if (window.lockedUntil > now) {
                return Math.max(1L, (long) Math.ceil((window.lockedUntil - now) / 1000.0));
            }
            while (!window.stamps.isEmpty() && now - window.stamps.peekFirst() > 60_000L) {
                window.stamps.removeFirst();
            }
            if (window.stamps.size() >= limit) {
                window.lockedUntil = now + LOCK_MILLIS;
                window.stamps.clear();
                return LOCK_MILLIS / 1000L;
            }
            window.stamps.addLast(now);
            return 0L;
        }
    }

    private static final class Window {
        private final Deque<Long> stamps = new ArrayDeque<>();
        private long lockedUntil;
    }
}