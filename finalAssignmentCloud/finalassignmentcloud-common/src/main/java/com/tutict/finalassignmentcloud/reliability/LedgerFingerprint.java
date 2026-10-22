package com.tutict.finalassignmentcloud.reliability;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;

/**
 * 台账请求指纹。指纹写入 {@code sys_request_history.request_params}，
 * 用于识别“同一个幂等键被复用于不同请求体”的冲突。
 *
 * <p>前缀 {@code sha256:} 与单体后端保持一致：两套实现读写同一张台账时，
 * 单体后端的 {@code markSuccess} 会保留带此前缀的指纹，不会覆盖成 {@code DONE}。
 */
public final class LedgerFingerprint {

    public static final String PREFIX = "sha256:";

    private static final int DIGEST_LENGTH = 64;

    private LedgerFingerprint() {
    }

    /** 纯摘要（64 位十六进制），用于派生幂等键。 */
    public static String sha256(String canonical) {
        try {
            byte[] hash = MessageDigest.getInstance("SHA-256")
                    .digest((canonical == null ? "" : canonical).getBytes(StandardCharsets.UTF_8));
            return java.util.HexFormat.of().formatHex(hash);
        } catch (NoSuchAlgorithmException ex) {
            throw new IllegalStateException(ex);
        }
    }

    /** 带前缀的请求指纹，写入台账的 {@code request_params}。 */
    public static String fingerprint(String canonical) {
        return PREFIX + sha256(canonical);
    }

    public static boolean isFingerprint(String value) {
        if (value == null || !value.startsWith(PREFIX)) {
            return false;
        }
        String digest = value.substring(PREFIX.length());
        if (digest.length() != DIGEST_LENGTH) {
            return false;
        }
        for (int i = 0; i < digest.length(); i++) {
            char c = digest.charAt(i);
            boolean hex = (c >= '0' && c <= '9') || (c >= 'a' && c <= 'f') || (c >= 'A' && c <= 'F');
            if (!hex) {
                return false;
            }
        }
        return true;
    }

    /**
     * 旧版本写入的占位值：没有请求指纹，无法判断是否同键异内容，只能按“已处理”对待。
     */
    public static boolean isLegacyMarker(String value) {
        if (value == null || value.isBlank()) {
            return true;
        }
        String trimmed = value.trim();
        return "PENDING".equalsIgnoreCase(trimmed) || "DONE".equalsIgnoreCase(trimmed);
    }
}
