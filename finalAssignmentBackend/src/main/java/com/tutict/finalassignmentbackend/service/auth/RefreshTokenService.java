package com.tutict.finalassignmentbackend.service.auth;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.core.conditions.update.UpdateWrapper;
import com.tutict.finalassignmentbackend.entity.auth.RefreshToken;
import com.tutict.finalassignmentbackend.mapper.auth.RefreshTokenMapper;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.security.SecureRandom;
import java.time.LocalDateTime;
import java.util.Base64;
import java.util.List;

@Service
public class RefreshTokenService {

    private static final SecureRandom SECURE_RANDOM = new SecureRandom();
    private static final int REFRESH_TOKEN_BYTES = 32;

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
                        return false; // 旧 BCrypt 哈希或损坏数据，无法解密
                    }
                    return pqcTokenCrypto.constantTimeEquals(raw, decrypted);
                })
                .findFirst()
                .orElseThrow(() -> new BadCredentialsException("Invalid refresh token"));
    }

    private String generateRawToken() {
        byte[] bytes = new byte[REFRESH_TOKEN_BYTES];
        SECURE_RANDOM.nextBytes(bytes);
        return Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
    }
}
