package com.tutict.finalassignmentcloud.auth.reliability;

import com.tutict.finalassignmentcloud.reliability.LedgerFingerprint;
import java.nio.charset.StandardCharsets;
import java.security.GeneralSecurityException;
import java.util.HexFormat;
import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

/**
 * 注册请求指纹。
 *
 * <p>指纹覆盖密码，因此必须是带密钥的摘要：裸 sha256(password) 与口令哈希等价，
 * 落到 {@code sys_request_history.request_params} 后即可离线爆破。HMAC 的密钥不在台账里，
 * 即使台账泄露也无法反推口令。
 *
 * <p>指纹沿用台账通用的 {@code sha256:} 前缀，单体与微服务两套实现才能互相识别同一行记录。
 */
@Component
public class RegistrationFingerprint {

    private static final String HMAC_ALGORITHM = "HmacSHA256";
    private static final String KEY_DERIVATION_LABEL = "final-assignment/auth/registration-fingerprint/v1";
    private static final String CANONICAL_PREFIX = "USER_REGISTRATION|";

    private final byte[] key;

    public RegistrationFingerprint(
            @Value("${auth.registration.fingerprint.secret:}") String dedicatedSecret,
            @Value("${internal.service-token:}") String internalServiceToken) {
        String secret = dedicatedSecret != null && !dedicatedSecret.isBlank()
                ? dedicatedSecret
                : internalServiceToken;
        if (secret == null || secret.isBlank()) {
            throw new IllegalStateException("auth.registration.fingerprint.secret must be provided through "
                    + "AUTH_FINGERPRINT_SECRET or configuration");
        }
        this.key = mac(KEY_DERIVATION_LABEL.getBytes(StandardCharsets.UTF_8),
                secret.getBytes(StandardCharsets.UTF_8));
    }

    /**
     * 同一份注册请求在任何一次重试中都得到同一个指纹；
     * 换了用户名或密码则得到不同指纹，台账据此判定为冲突。
     */
    public String fingerprint(String username, String password) {
        String canonical = CANONICAL_PREFIX + (username == null ? "" : username)
                + "|" + (password == null ? "" : password);
        return LedgerFingerprint.PREFIX + HexFormat.of().formatHex(mac(canonical.getBytes(StandardCharsets.UTF_8), key));
    }

    private static byte[] mac(byte[] data, byte[] keyBytes) {
        try {
            Mac mac = Mac.getInstance(HMAC_ALGORITHM);
            mac.init(new SecretKeySpec(keyBytes, HMAC_ALGORITHM));
            return mac.doFinal(data);
        } catch (GeneralSecurityException ex) {
            throw new IllegalStateException("Unable to compute the registration fingerprint", ex);
        }
    }
}
