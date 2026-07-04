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

import java.security.SecureRandom;
import java.time.LocalDateTime;
import java.util.Base64;
import java.util.List;

/**
 * 刷新令牌服务：签发 / 校验 / 轮换 / 撤销。令牌以 ML-KEM 信封（{@link PqcTokenCrypto}）
 * 后量子加密后落库，明文只在签发时返回给客户端。对齐 Spring service/auth/RefreshTokenService。
 */
@ApplicationScoped
public class RefreshTokenService {

    private static final SecureRandom SECURE_RANDOM = new SecureRandom();
    private static final int REFRESH_TOKEN_BYTES = 32;

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

        QueryWrapper<RefreshToken> query = new QueryWrapper<>();
        query.eq("revoked", false)
                .gt("expires_at", LocalDateTime.now());
        List<RefreshToken> candidates = refreshTokenMapper.selectList(query);

        return candidates.stream()
                .filter(candidate -> {
                    String decrypted;
                    try {
                        decrypted = pqcTokenCrypto.decrypt(candidate.getToken());
                    } catch (Exception ex) {
                        return false; // 损坏或不可解密的数据，跳过
                    }
                    return pqcTokenCrypto.constantTimeEquals(raw, decrypted);
                })
                .findFirst()
                .orElseThrow(() -> new AuthenticationFailedException("Invalid refresh token"));
    }

    private String generateRawToken() {
        byte[] bytes = new byte[REFRESH_TOKEN_BYTES];
        SECURE_RANDOM.nextBytes(bytes);
        return Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
    }
}
