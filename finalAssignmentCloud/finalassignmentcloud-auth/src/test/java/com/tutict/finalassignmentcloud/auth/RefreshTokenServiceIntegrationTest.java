package com.tutict.finalassignmentcloud.auth;

import com.tutict.finalassignmentcloud.auth.service.PqcTokenCrypto;
import com.tutict.finalassignmentcloud.auth.service.RefreshTokenService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.MethodOrderer;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.TestMethodOrder;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.test.context.ActiveProfiles;

import static org.junit.jupiter.api.Assertions.*;

/**
 * Cloud 端 refresh token 生命周期集成测试：创建、校验、旋转（旧 token 失效）、吊销。
 */
@SpringBootTest
@ActiveProfiles("test")
@TestMethodOrder(MethodOrderer.OrderAnnotation.class)
class RefreshTokenServiceIntegrationTest {

    @Autowired
    private RefreshTokenService refreshTokenService;

    @Autowired
    private PqcTokenCrypto pqcTokenCrypto;

    private static final Long TEST_USER_ID = 1L;

    @BeforeEach
    void cleanUp() {
        refreshTokenService.revokeUserTokens(TEST_USER_ID);
    }

    @Test
    @DisplayName("创建并校验 refresh token")
    void createAndValidate() {
        String raw = refreshTokenService.createRefreshToken(TEST_USER_ID);
        assertNotNull(raw);
        assertFalse(raw.isBlank());

        Long resolvedUserId = refreshTokenService.validateRefreshToken(raw);
        assertEquals(TEST_USER_ID, resolvedUserId);
    }

    @Test
    @DisplayName("旋转后旧 token 失效，新 token 可校验")
    void rotateInvalidatesOldToken() {
        String raw = refreshTokenService.createRefreshToken(TEST_USER_ID);
        assertNotNull(refreshTokenService.validateRefreshToken(raw), "initial token should be valid");

        String rotated = refreshTokenService.rotateRefreshToken(TEST_USER_ID, raw);
        assertNotNull(rotated);
        assertNotEquals(raw, rotated, "rotated token should differ");

        assertThrows(BadCredentialsException.class, () -> refreshTokenService.validateRefreshToken(raw),
                "old token must be rejected after rotation");
        assertEquals(TEST_USER_ID, refreshTokenService.validateRefreshToken(rotated),
                "new token should validate after rotation");
    }

    @Test
    @DisplayName("旋转同一 token 两次会被拒绝（乐观锁防并发重用）")
    void doubleRotateRejected() {
        String raw = refreshTokenService.createRefreshToken(TEST_USER_ID);
        String first = refreshTokenService.rotateRefreshToken(TEST_USER_ID, raw);
        assertNotNull(first);
        assertThrows(BadCredentialsException.class, () -> refreshTokenService.rotateRefreshToken(TEST_USER_ID, raw),
                "reusing the same token to rotate again must be rejected");
    }

    @Test
    @DisplayName("吊销用户全部 token")
    void revokeUserTokens() {
        String raw1 = refreshTokenService.createRefreshToken(TEST_USER_ID);
        String raw2 = refreshTokenService.createRefreshToken(TEST_USER_ID);
        assertNotNull(refreshTokenService.validateRefreshToken(raw1));
        assertNotNull(refreshTokenService.validateRefreshToken(raw2));

        refreshTokenService.revokeUserTokens(TEST_USER_ID);

        assertThrows(BadCredentialsException.class, () -> refreshTokenService.validateRefreshToken(raw1),
                "revoked token must be rejected");
        assertThrows(BadCredentialsException.class, () -> refreshTokenService.validateRefreshToken(raw2),
                "revoked token must be rejected");
    }

    @Test
    @DisplayName("无效 token 被拒绝")
    void invalidTokenRejected() {
        assertThrows(BadCredentialsException.class, () -> refreshTokenService.validateRefreshToken("garbage-token"));
        assertThrows(BadCredentialsException.class, () -> refreshTokenService.validateRefreshToken(null));
        assertThrows(BadCredentialsException.class, () -> refreshTokenService.validateRefreshToken(""));
    }

    @Test
    @DisplayName("PqcTokenCrypto 加解密往返一致")
    void cryptoRoundTrip() {
        String plaintext = "test-refresh-token-value-123";
        String encrypted = pqcTokenCrypto.encrypt(plaintext);
        assertNotNull(encrypted);
        assertNotEquals(plaintext, encrypted);
        assertEquals(plaintext, pqcTokenCrypto.decrypt(encrypted));
        assertTrue(pqcTokenCrypto.constantTimeEquals(plaintext, pqcTokenCrypto.decrypt(encrypted)));
        assertFalse(pqcTokenCrypto.constantTimeEquals(plaintext, "different"));
    }
}