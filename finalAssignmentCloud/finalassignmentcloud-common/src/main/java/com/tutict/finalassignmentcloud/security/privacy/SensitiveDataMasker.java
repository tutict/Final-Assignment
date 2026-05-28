package com.tutict.finalassignmentcloud.security.privacy;

import org.springframework.util.StringUtils;

public final class SensitiveDataMasker {

    private SensitiveDataMasker() {
    }

    public static String idCard(String value) {
        String normalized = trim(value);
        if (normalized == null || normalized.length() < 10) {
            return normalized;
        }
        return normalized.substring(0, 6) + "********" + normalized.substring(normalized.length() - 4);
    }

    public static String phone(String value) {
        String normalized = trim(value);
        if (normalized == null || normalized.length() < 7) {
            return normalized;
        }
        int prefixLength = Math.min(3, normalized.length());
        int suffixLength = Math.min(4, normalized.length() - prefixLength);
        int suffixStart = normalized.length() - suffixLength;
        return normalized.substring(0, prefixLength) + "****" + normalized.substring(suffixStart);
    }

    public static String bankAccount(String value) {
        String normalized = trim(value);
        if (normalized == null || normalized.length() < 8) {
            return normalized;
        }
        return normalized.substring(0, 4) + "****" + normalized.substring(normalized.length() - 4);
    }

    private static String trim(String value) {
        return StringUtils.hasText(value) ? value.trim() : value;
    }
}
