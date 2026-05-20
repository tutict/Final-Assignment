package com.tutict.finalassignmentbackend.service;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.HexFormat;
import java.util.concurrent.TimeUnit;

@Service
public class TokenBlacklistService {

    private static final Logger LOG = LoggerFactory.getLogger(TokenBlacklistService.class);
    private static final String BLACKLIST_PREFIX = "blacklist:";

    private final RedisTemplate<String, Object> redisTemplate;
    private final boolean failOpenWhenUnavailable;

    public TokenBlacklistService(
            RedisTemplate<String, Object> redisTemplate,
            @Value("${app.security.token-blacklist.fail-open:false}") boolean failOpenWhenUnavailable) {
        this.redisTemplate = redisTemplate;
        this.failOpenWhenUnavailable = failOpenWhenUnavailable;
    }

    public void blacklist(String token, long ttlMillis) {
        if (!StringUtils.hasText(token) || ttlMillis <= 0) {
            return;
        }
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

    public boolean isBlacklisted(String token) {
        if (!StringUtils.hasText(token)) {
            return false;
        }
        try {
            return Boolean.TRUE.equals(redisTemplate.hasKey(key(token)));
        } catch (RuntimeException ex) {
            LOG.error("Failed to check access token blacklist", ex);
            return !failOpenWhenUnavailable;
        }
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
