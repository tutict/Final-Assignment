package com.tutict.finalassignmentbackend.service.auth;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import com.tutict.finalassignmentbackend.reliability.BlacklistAccessPolicy;
import java.util.HexFormat;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.TimeUnit;

@Service
public class TokenBlacklistService {

    private static final Logger LOG = LoggerFactory.getLogger(TokenBlacklistService.class);
    private static final String BLACKLIST_PREFIX = "blacklist:";

    private final RedisTemplate<String, Object> redisTemplate;
    private final boolean failOpenWhenUnavailable;
    private final ConcurrentHashMap<String, Long> localRevocations = new ConcurrentHashMap<>();

    public TokenBlacklistService(
            @Qualifier("blacklistRedisTemplate") RedisTemplate<String, Object> redisTemplate,
            @Value("${app.security.token-blacklist.fail-open:false}") boolean failOpenWhenUnavailable) {
        this.redisTemplate = redisTemplate;
        this.failOpenWhenUnavailable = failOpenWhenUnavailable;
    }

    public void blacklist(String token, long ttlMillis) {
        if (!StringUtils.hasText(token) || ttlMillis <= 0) {
            return;
        }
        remember(token, ttlMillis);
        try {
            redisTemplate.opsForValue().set(key(token), "revoked", ttlMillis, TimeUnit.MILLISECONDS);
        } catch (RuntimeException ex) {
            if (failOpenWhenUnavailable) {
                LOG.warn("Failed to blacklist access token because Redis is unavailable", ex);
                return;
            }
            throw ex;
        }
    }

    public BlacklistAccessPolicy.Verdict inspect(String token) {
        if (!StringUtils.hasText(token)) {
            return BlacklistAccessPolicy.Verdict.CLEAR;
        }
        if (locallyRevoked(token)) {
            return BlacklistAccessPolicy.Verdict.REVOKED;
        }
        try {
            if (Boolean.TRUE.equals(redisTemplate.hasKey(key(token)))) {
                remember(token, TimeUnit.MINUTES.toMillis(30));
                return BlacklistAccessPolicy.Verdict.REVOKED;
            }
            return BlacklistAccessPolicy.Verdict.CLEAR;
        } catch (RuntimeException ex) {
            LOG.error("Failed to check access token blacklist", ex);
            return locallyRevoked(token)
                    ? BlacklistAccessPolicy.Verdict.REVOKED
                    : BlacklistAccessPolicy.Verdict.UNAVAILABLE;
        }
    }

    public boolean redisReachable() {
        try {
            redisTemplate.hasKey("reliability:redis-ping");
            return true;
        } catch (RuntimeException ex) {
            LOG.warn("Redis blacklist dependency is unavailable", ex);
            return false;
        }
    }

    public boolean isBlacklisted(String token) {
        if (!StringUtils.hasText(token)) {
            return false;
        }
        return inspect(token) == BlacklistAccessPolicy.Verdict.REVOKED;
    }

    private void remember(String token, long ttlMillis) {
        localRevocations.put(sha256(token), System.currentTimeMillis() + Math.max(ttlMillis, 1));
    }

    private boolean locallyRevoked(String token) {
        Long until = localRevocations.get(sha256(token));
        if (until == null) {
            return false;
        }
        if (until < System.currentTimeMillis()) {
            localRevocations.remove(sha256(token));
            return false;
        }
        return true;
    }

    private String key(String token) {
        return BLACKLIST_PREFIX + sha256(token);
    }

    private String sha256(String value) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            return HexFormat.of().formatHex(digest.digest(value.getBytes(StandardCharsets.UTF_8)));
        } catch (NoSuchAlgorithmException ex) {
            throw new IllegalStateException("SHA-256 algorithm is unavailable", ex);
        }
    }
}
