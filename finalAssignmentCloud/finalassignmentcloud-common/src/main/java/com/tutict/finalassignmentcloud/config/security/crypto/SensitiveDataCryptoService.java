package com.tutict.finalassignmentcloud.config.security.crypto;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;

import javax.crypto.Cipher;
import javax.crypto.Mac;
import javax.crypto.spec.GCMParameterSpec;
import javax.crypto.spec.SecretKeySpec;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.SecureRandom;
import java.util.Arrays;
import java.util.Base64;
import java.util.Locale;

@Service
public class SensitiveDataCryptoService {

    private static final String PREFIX = "enc:v1:";
    private static final int GCM_IV_BYTES = 12;
    private static final int GCM_TAG_BITS = 128;

    private final boolean enabled;
    private final SecretKeySpec encryptionKey;
    private final SecretKeySpec blindIndexKey;
    private final SecureRandom secureRandom = new SecureRandom();

    public SensitiveDataCryptoService(
            @Value("${app.security.sensitive-data.encryption.enabled:false}") boolean enabled,
            @Value("${app.security.sensitive-data.encryption.key:}") String encryptionKey,
            @Value("${app.security.sensitive-data.blind-index.key:}") String blindIndexKey
    ) {
        this.enabled = enabled;
        if (enabled && !StringUtils.hasText(encryptionKey)) {
            throw new IllegalStateException("Sensitive data encryption is enabled but no encryption key was configured");
        }
        this.encryptionKey = StringUtils.hasText(encryptionKey)
                ? new SecretKeySpec(normalizeKey(encryptionKey), "AES")
                : null;
        this.blindIndexKey = StringUtils.hasText(blindIndexKey)
                ? new SecretKeySpec(normalizeKey(blindIndexKey), "HmacSHA256")
                : (this.encryptionKey == null ? null : new SecretKeySpec(this.encryptionKey.getEncoded(), "HmacSHA256"));
    }

    public boolean isEnabled() {
        return enabled && encryptionKey != null;
    }

    public String encrypt(String plaintext) {
        if (!isEnabled() || !StringUtils.hasText(plaintext) || isEncrypted(plaintext)) {
            return plaintext;
        }
        try {
            byte[] iv = new byte[GCM_IV_BYTES];
            secureRandom.nextBytes(iv);
            Cipher cipher = Cipher.getInstance("AES/GCM/NoPadding");
            cipher.init(Cipher.ENCRYPT_MODE, encryptionKey, new GCMParameterSpec(GCM_TAG_BITS, iv));
            byte[] ciphertext = cipher.doFinal(plaintext.getBytes(StandardCharsets.UTF_8));
            byte[] payload = new byte[iv.length + ciphertext.length];
            System.arraycopy(iv, 0, payload, 0, iv.length);
            System.arraycopy(ciphertext, 0, payload, iv.length, ciphertext.length);
            return PREFIX + Base64.getUrlEncoder().withoutPadding().encodeToString(payload);
        } catch (Exception error) {
            throw new IllegalStateException("Failed to encrypt sensitive data", error);
        }
    }

    public String decrypt(String value) {
        if (!isEnabled() || !isEncrypted(value)) {
            return value;
        }
        try {
            byte[] payload = Base64.getUrlDecoder().decode(value.substring(PREFIX.length()));
            byte[] iv = Arrays.copyOfRange(payload, 0, GCM_IV_BYTES);
            byte[] ciphertext = Arrays.copyOfRange(payload, GCM_IV_BYTES, payload.length);
            Cipher cipher = Cipher.getInstance("AES/GCM/NoPadding");
            cipher.init(Cipher.DECRYPT_MODE, encryptionKey, new GCMParameterSpec(GCM_TAG_BITS, iv));
            return new String(cipher.doFinal(ciphertext), StandardCharsets.UTF_8);
        } catch (Exception error) {
            throw new IllegalStateException("Failed to decrypt sensitive data", error);
        }
    }

    public String blindIndex(String value) {
        if (!StringUtils.hasText(value) || blindIndexKey == null) {
            return null;
        }
        try {
            Mac mac = Mac.getInstance("HmacSHA256");
            mac.init(blindIndexKey);
            byte[] digest = mac.doFinal(normalizeForIndex(value).getBytes(StandardCharsets.UTF_8));
            return Base64.getUrlEncoder().withoutPadding().encodeToString(digest);
        } catch (Exception error) {
            throw new IllegalStateException("Failed to calculate sensitive data blind index", error);
        }
    }

    public boolean isEncrypted(String value) {
        return value != null && value.startsWith(PREFIX);
    }

    private static String normalizeForIndex(String value) {
        return value.trim().replaceAll("\\s+", "").toUpperCase(Locale.ROOT);
    }

    private static byte[] normalizeKey(String value) {
        String trimmed = value.trim();
        try {
            byte[] decoded = Base64.getDecoder().decode(trimmed);
            if (decoded.length == 16 || decoded.length == 24 || decoded.length == 32) {
                return decoded;
            }
        } catch (IllegalArgumentException ignored) {
        }
        try {
            return MessageDigest.getInstance("SHA-256").digest(trimmed.getBytes(StandardCharsets.UTF_8));
        } catch (Exception error) {
            throw new IllegalStateException("SHA-256 is not available", error);
        }
    }
}
