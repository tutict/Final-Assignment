package com.tutict.finalassignmentcloud.config.security;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.HexFormat;
import java.util.Map;

final class ServiceRevocation {

    enum Verdict { CLEAR, REVOKED, UNAVAILABLE }

    private ServiceRevocation() {
    }

    static Verdict inspect(Map<String, Long> local, String token, Boolean redisHasKey) {
        if (locallyRevoked(local, token)) {
            return Verdict.REVOKED;
        }
        if (redisHasKey == null) {
            return Verdict.UNAVAILABLE;
        }
        if (redisHasKey) {
            remember(local, token, 30L * 60L * 1000L);
            return Verdict.REVOKED;
        }
        return Verdict.CLEAR;
    }

    static boolean shed(String method, String path, Verdict verdict) {
        if (verdict == Verdict.REVOKED || verdict == Verdict.CLEAR) {
            return false;
        }
        return isWrite(method) || isLoginOrRefresh(path);
    }

    static boolean denied(Verdict verdict) {
        return verdict == Verdict.REVOKED;
    }

    static byte[] redisKey(String token) {
        return ("blacklist:" + sha256(token)).getBytes(StandardCharsets.UTF_8);
    }

    private static void remember(Map<String, Long> local, String token, long ttlMillis) {
        local.put(sha256(token), System.currentTimeMillis() + Math.max(ttlMillis, 1));
    }

    private static boolean locallyRevoked(Map<String, Long> local, String token) {
        Long until = local.get(sha256(token));
        if (until == null) {
            return false;
        }
        if (until < System.currentTimeMillis()) {
            local.remove(sha256(token));
            return false;
        }
        return true;
    }

    private static boolean isWrite(String method) {
        return "POST".equalsIgnoreCase(method)
                || "PUT".equalsIgnoreCase(method)
                || "PATCH".equalsIgnoreCase(method)
                || "DELETE".equalsIgnoreCase(method);
    }

    private static boolean isLoginOrRefresh(String path) {
        return path != null && (path.contains("/api/auth/login") || path.contains("/api/auth/refresh"));
    }

    private static String sha256(String value) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            return HexFormat.of().formatHex(digest.digest(value.getBytes(StandardCharsets.UTF_8)));
        } catch (NoSuchAlgorithmException ex) {
            throw new IllegalStateException(ex);
        }
    }
}
