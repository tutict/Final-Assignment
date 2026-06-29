package com.tutict.finalassignmentbackend.integration.pqc;

import static org.assertj.core.api.Assertions.assertThat;

import com.tutict.finalassignmentbackend.config.login.jwt.TokenProvider;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.test.util.ReflectionTestUtils;

/**
 * 验证 {@link TokenProvider} 的 ML-DSA-65 签发/校验路径与 Bouncy Castle Signature API。
 * 无 PEM 配置时走临时密钥对。
 */
@DisplayName("ML-DSA JWT 签验往返测试")
class TokenProviderMlDsaIntegrationTest {

    private TokenProvider newMlDsaProvider() {
        TokenProvider tp = new TokenProvider();
        ReflectionTestUtils.setField(tp, "configuredAlgorithm", "ML-DSA-65");
        ReflectionTestUtils.setField(tp, "accessTokenExpirationSeconds", 3600L);
        tp.init();
        return tp;
    }

    @Test
    @DisplayName("createEnhancedToken 签发后 validateToken 通过，claims 可正确提取")
    void signAndVerifyRoundTrip() {
        TokenProvider tp = newMlDsaProvider();
        String token = tp.createEnhancedToken("alice", "USER", "CUSTOM", "SELF");

        assertThat(tp.validateToken(token)).isTrue();
        assertThat(tp.getUsernameFromToken(token)).isEqualTo("alice");
        assertThat(tp.extractRoles(token)).contains("ROLE_USER");
        assertThat(tp.getExpirationMs(token)).isPositive();
    }

    @Test
    @DisplayName("篡改 payload 后 validateToken 失败")
    void tamperedTokenFails() {
        TokenProvider tp = newMlDsaProvider();
        String token = tp.createEnhancedToken("bob", "USER", "CUSTOM", "SELF");

        String[] parts = token.split("\\.", 3);
        // 翻转 payload 最后一字符，重算 base64url（保持无 padding）
        byte[] payload = java.util.Base64.getUrlDecoder().decode(parts[1]);
        payload[0] ^= 0x01;
        String tamperedPayload = java.util.Base64.getUrlEncoder().withoutPadding().encodeToString(payload);
        String tampered = parts[0] + "." + tamperedPayload + "." + parts[2];

        assertThat(tp.validateToken(tampered)).isFalse();
    }

    @Test
    @DisplayName("createToken（基础 claims）同样可签可验")
    void basicTokenRoundTrip() {
        TokenProvider tp = newMlDsaProvider();
        String token = tp.createToken("carol", "USER");
        assertThat(tp.validateToken(token)).isTrue();
        assertThat(tp.getUsernameFromToken(token)).isEqualTo("carol");
    }

    @Test
    @DisplayName("HS256 默认路径仍可用（回归：算法切换不影响 HMAC）")
    void hs256StillWorks() {
        TokenProvider tp = new TokenProvider();
        ReflectionTestUtils.setField(tp, "configuredAlgorithm", "HS256");
        ReflectionTestUtils.setField(tp, "secret", "0123456789abcdef0123456789abcdef");
        ReflectionTestUtils.setField(tp, "accessTokenExpirationSeconds", 3600L);
        tp.init();
        String token = tp.createToken("dave", "USER");
        assertThat(tp.validateToken(token)).isTrue();
        assertThat(tp.getUsernameFromToken(token)).isEqualTo("dave");
    }
}
