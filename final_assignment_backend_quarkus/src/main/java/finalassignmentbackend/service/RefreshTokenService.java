package finalassignmentbackend.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.core.conditions.update.UpdateWrapper;
import finalassignmentbackend.entity.RefreshToken;
import finalassignmentbackend.mapper.RefreshTokenMapper;
import io.quarkus.security.AuthenticationFailedException;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.transaction.Transactional;
import org.eclipse.microprofile.config.inject.ConfigProperty;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.nio.charset.StandardCharsets;
import java.security.SecureRandom;
import java.time.LocalDateTime;
import java.util.Base64;
import java.util.HexFormat;
import java.util.List;

/**
 * 刷新令牌服务：签发 / 校验 / 轮换 / 撤销。令牌以 ML-KEM 信封（{@link PqcTokenCrypto}）
 * 后量子加密后落库，明文只在签发时返回给客户端。对齐 Spring service/auth/RefreshTokenService。
 *
 * <p>查找优化：存储时额外写 {@code lookup_digest}（HMAC-SHA-256(raw)），校验/轮换先按 digest 做 O(1)
 * 单行查询；历史无 digest 的令牌回落到全表扫描并回填 digest（一次性迁移）。
 */
@ApplicationScoped
public class RefreshTokenService {

    private static final SecureRandom SECURE_RANDOM = new SecureRandom();
    private static final int REFRESH_TOKEN_BYTES = 32;
    private static final String HMAC_ALGORITHM = "HmacSHA256";
    private static final String HMAC_KEY = "refresh-token-lookup-v1";

    @Inject
    RefreshTokenMapper refreshTokenMapper;

    @Inject
    PqcTokenCrypto pqcTokenCrypto;

    @ConfigProperty(name = "jwt.refresh-token-expiration", defaultValue = "604800")
    long refreshExpirationSeconds;

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

    @Transactional
    public Long validateRefreshToken(String raw) {
        RefreshToken token = requireActiveToken(raw);
        return token.getUserId();
    }

    @Transactional
    public String rotateRefreshToken(Long userId, String raw) {
        RefreshToken existing = requireActiveToken(raw);
        if (!existing.getUserId().equals(userId)) {
            throw new AuthenticationFailedException("Invalid refresh token");
        }

        // Use optimistic locking via id + revoked=false to handle concurrent rotate
        UpdateWrapper<RefreshToken> update = new UpdateWrapper<>();
        update.eq("id", existing.getId())
                .eq("revoked", false)
                .set("revoked", true);
        int rows = refreshTokenMapper.update(null, update);
        if (rows == 0) {
            throw new AuthenticationFailedException("Refresh token has already been used");
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
        if (raw == null || raw.isBlank()) {
            throw new AuthenticationFailedException("Refresh token is required");
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
                throw new AuthenticationFailedException("Invalid refresh token");
            }
        }

        // Constant-time comparison
        String decrypted;
        try {
            decrypted = pqcTokenCrypto.decrypt(token.getToken());
        } catch (Exception ex) {
            throw new AuthenticationFailedException("Invalid refresh token");
        }

        if (!pqcTokenCrypto.constantTimeEquals(raw, decrypted)) {
            throw new AuthenticationFailedException("Invalid refresh token");
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
        List<RefreshToken> candidates = refreshTokenMapper.selectList(query);

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
                    HMAC_KEY.getBytes(StandardCharsets.UTF_8), HMAC_ALGORITHM);
            mac.init(keySpec);
            return HexFormat.of().formatHex(mac.doFinal(raw.getBytes(StandardCharsets.UTF_8)));
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
