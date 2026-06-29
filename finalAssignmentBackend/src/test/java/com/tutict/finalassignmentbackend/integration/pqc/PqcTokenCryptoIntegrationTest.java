package com.tutict.finalassignmentbackend.integration.pqc;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.tutict.finalassignmentbackend.service.auth.PqcTokenCrypto;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

/**
 * 验证 Bouncy Castle 的 ML-KEM-768 API 与 {@link PqcTokenCrypto} 信封加解密。
 * 不依赖 Spring 上下文：直接 new 出来手动 init()（无 PEM 配置时走临时密钥对）。
 */
@DisplayName("ML-KEM 信封加解密往返测试")
class PqcTokenCryptoIntegrationTest {

    private PqcTokenCrypto newInstance() {
        PqcTokenCrypto crypto = new PqcTokenCrypto();
        crypto.init();
        return crypto;
    }

    @Test
    @DisplayName("encrypt 后 decrypt 还原原文")
    void encryptDecryptRoundTrip() {
        PqcTokenCrypto crypto = newInstance();
        String raw = "aVerySecretRefreshToken-Base64UrlEncoded-123456";

        String blob = crypto.encrypt(raw);

        assertThat(blob).isNotEqualTo(raw);
        assertThat(crypto.decrypt(blob)).isEqualTo(raw);
    }

    @Test
    @DisplayName("每次 encrypt 产生不同密文（随机 AES key/nonce）")
    void encryptIsNonDeterministic() {
        PqcTokenCrypto crypto = newInstance();
        String raw = "same-plaintext";

        String a = crypto.encrypt(raw);
        String b = crypto.encrypt(raw);

        assertThat(a).isNotEqualTo(b);
        assertThat(crypto.decrypt(a)).isEqualTo(raw);
        assertThat(crypto.decrypt(b)).isEqualTo(raw);
    }

    @Test
    @DisplayName("篡改密文应导致解密失败")
    void tamperedBlobFailsToDecrypt() {
        PqcTokenCrypto crypto = newInstance();
        String blob = crypto.encrypt("plaintext");

        byte[] bytes = java.util.Base64.getDecoder().decode(blob);
        bytes[bytes.length - 1] ^= 0x01; // 翻转 GCM tag 最后一字节
        String tampered = java.util.Base64.getEncoder().encodeToString(bytes);

        assertThatThrownBy(() -> crypto.decrypt(tampered))
                .isInstanceOf(Exception.class);
    }

    @Test
    @DisplayName("constantTimeEquals：相同 true、不同 false、长度不同 false")
    void constantTimeEqualsBehaves() {
        PqcTokenCrypto crypto = newInstance();
        assertThat(crypto.constantTimeEquals("abc", "abc")).isTrue();
        assertThat(crypto.constantTimeEquals("abc", "abd")).isFalse();
        assertThat(crypto.constantTimeEquals("abc", "abcd")).isFalse();
        assertThat(crypto.constantTimeEquals(null, null)).isTrue();
        assertThat(crypto.constantTimeEquals(null, "x")).isFalse();
    }
}
