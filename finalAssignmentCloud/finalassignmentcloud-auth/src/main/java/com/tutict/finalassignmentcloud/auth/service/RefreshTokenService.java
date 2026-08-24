package com.tutict.finalassignmentcloud.auth.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.core.conditions.update.UpdateWrapper;
import com.tutict.finalassignmentcloud.auth.entity.auth.RefreshToken;
import com.tutict.finalassignmentcloud.auth.mapper.auth.RefreshTokenMapper;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.security.SecureRandom;
import java.time.LocalDateTime;
import java.util.Base64;
import java.util.HexFormat;

/**
 * refresh token 生命周期管理：创建、校验、旋转、吊销。
 *
 * <p>与 monolith 的 RefreshTokenService 保持同一套契约：
 * <ul>
 *   <li>token 静态加密存储（ML-KEM 信封），明文不落库；</li>
 *   <li>lookup_digest（HMAC-SHA-256）唯一索引，O(1) 查找；</li>
 *   <li>旋转用乐观锁（id + revoked=false）防御并发重用；</li>
 *   <li>遗留无 digest 旧行：首次使用时线性回扫并 backfill。</li>
 * </ul>
 */
@Service
public class RefreshTokenService {

    private static final SecureRandom SECURE_RANDOM = new SecureRandom();
    private static final int REFRESH_TOKEN_BYTES = 32;
    private static final String HMAC_ALGORITHM = "HmacSHA256";
    private static final String HMAC_KEY = "refresh-token-lookup-v1";

    private final RefreshTokenMapper refreshTokenMapper;
    private final PqcTokenCrypto pqcTokenCrypto;
    private final long refreshExpirationSeconds;

    public RefreshTokenService(RefreshTokenMapper refreshTokenMapper,
                               PqcTokenCrypto pqcTokenCrypto,
                               @Value("${jwt.refresh-token-expiration:604800}") long refreshExpirationSeconds) {
        this.refreshTokenMapper = refreshTokenMapper;
        this.pqcTokenCrypto = pqcTokenCrypto;
        this.refreshExpirationSeconds = refreshExpirationSeconds;
    }

    @Transactional
    public String createRefreshToken(Long userId) {
        if (userId == null) {
            throw new IllegalArgumentException("userId must not be null");
        }
        if (refreshExpirationSeconds <= 0) {
            throw new IllegalStateException("jwt.refresh-token-expiration must be greater than 0 seconds");
        }

        String raw = generateRawToken();
        LocalDateTime now = LocalDateTime.now();

        RefreshToken entity = new RefreshToken();
        entity.setToken(pqcTokenCrypto.encrypt(raw));
        entity.setLookupDigest(computeDigest(raw));
        entity.setUserId(userId);
        entity.setExpiresAt(now.plusSeconds(refreshExpirationSeconds));
        entity.setRevoked(false);
        entity.setCreatedAt(now);
        refreshTokenMapper.insert(entity);
        return raw;
    }

    @Transactional(readOnly = true)
    public Long validateRefreshToken(String raw) {
        RefreshToken token = requireActiveToken(raw);
        return token.getUserId();
    }

    @Transactional
    public String rotateRefreshToken(Long userId, String raw) {
        RefreshToken existing = requireActiveToken(raw);
        if (!existing.getUserId().equals(userId)) {
            throw new BadCredentialsException("Invalid refresh token");
        }

        // Use optimistic locking via id + revoked=false to handle concurrent rotate
        UpdateWrapper<RefreshToken> update = new UpdateWrapper<>();
        update.eq("id", existing.getId())
                .eq("revoked", false)
                .set("revoked", true);
        int rows = refreshTokenMapper.update(null, update);
        if (rows == 0) {
            throw new BadCredentialsException("Refresh token has already been used");
        }

        return createRefreshToken(userId);
    }

    @Transactional
    public void revokeUserTokens(Long userId) {
        if (userId == null) {
            return;
        }
        UpdateWrapper<RefreshToken> update = new UpdateWrapper<>();
        update.eq("user_id", userId)
                .eq("revoked", false)
                .set("revoked", true);
        refreshTokenMapper.update(null, update);
    }

    public long getRefreshTokenExpirationSeconds() {
        return refreshExpirationSeconds;
    }

    private RefreshToken requireActiveToken(String raw) {
        if (!StringUtils.hasText(raw)) {
            throw new BadCredentialsException("Refresh token is required");
        }

        String digest = computeDigest(raw);

        // O(1) lookup by digest - single row query instead of full table scan
        QueryWrapper<RefreshToken> query = new QueryWrapper<>();
        query.eq("lookup_digest", digest)
                .eq("revoked", false)
                .gt("expires_at", LocalDateTime.now());
        RefreshToken token = refreshTokenMapper.selectOne(query);

        if (token == null) {
            // Fallback: try legacy lookup without digest (for tokens created before migration)
            token = legacyLookup(raw);
            if (token == null) {
                throw new BadCredentialsException("Invalid refresh token");
            }
        }

        // Constant-time comparison
        String decrypted;
        try {
            decrypted = pqcTokenCrypto.decrypt(token.getToken());
        } catch (Exception ex) {
            throw new BadCredentialsException("Invalid refresh token");
        }

        if (!pqcTokenCrypto.constantTimeEquals(raw, decrypted)) {
            throw new BadCredentialsException("Invalid refresh token");
        }

        return token;
    }

    /**
     * Legacy fallback: scan all active tokens (one-time migration support).
     * This should not be called for new tokens that have lookup_digest.
     */
    private RefreshToken legacyLookup(String raw) {
        QueryWrapper<RefreshToken> query = new QueryWrapper<>();
        query.eq("revoked", false)
                .gt("expires_at", LocalDateTime.now())
                .isNull("lookup_digest")
                .last("LIMIT 100");
        var candidates = refreshTokenMapper.selectList(query);

        for (RefreshToken candidate : candidates) {
            String decrypted;
            try {
                decrypted = pqcTokenCrypto.decrypt(candidate.getToken());
            } catch (Exception ex) {
                continue;
            }
            if (pqcTokenCrypto.constantTimeEquals(raw, decrypted)) {
                // Backfill the digest for future O(1) lookups
                candidate.setLookupDigest(computeDigest(raw));
                refreshTokenMapper.updateById(candidate);
                return candidate;
            }
        }
        return null;
    }

    private String computeDigest(String raw) {
        try {
            Mac mac = Mac.getInstance(HMAC_ALGORITHM);
            SecretKeySpec keySpec = new SecretKeySpec(
                    HMAC_KEY.getBytes(java.nio.charset.StandardCharsets.UTF_8), HMAC_ALGORITHM);
            mac.init(keySpec);
            return HexFormat.of().formatHex(mac.doFinal(raw.getBytes(java.nio.charset.StandardCharsets.UTF_8)));
        } catch (Exception ex) {
            throw new IllegalStateException("Failed to compute refresh token digest", ex);
        }
    }

    private String generateRawToken() {
        byte[] bytes = new byte[REFRESH_TOKEN_BYTES];
        SECURE_RANDOM.nextBytes(bytes);
        return Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
    }
}