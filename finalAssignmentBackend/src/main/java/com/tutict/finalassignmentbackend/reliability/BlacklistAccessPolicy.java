package com.tutict.finalassignmentbackend.reliability;

public final class BlacklistAccessPolicy {

    public enum Verdict { CLEAR, REVOKED, UNAVAILABLE }

    public enum Effect { ALLOW, DENY, SHED }

    private BlacklistAccessPolicy() {
    }

    public static Effect decide(String method, String path, Verdict verdict) {
        if (verdict == Verdict.REVOKED) {
            return Effect.DENY;
        }
        if (verdict != Verdict.UNAVAILABLE) {
            return Effect.ALLOW;
        }
        if (isLoginOrRefresh(path) || isWrite(method)) {
            return Effect.SHED;
        }
        return Effect.ALLOW;
    }

    private static boolean isWrite(String method) {
        return "POST".equalsIgnoreCase(method)
                || "PUT".equalsIgnoreCase(method)
                || "PATCH".equalsIgnoreCase(method)
                || "DELETE".equalsIgnoreCase(method);
    }

    private static boolean isLoginOrRefresh(String path) {
        if (path == null) {
            return false;
        }
        return path.startsWith("/api/auth/login") || path.startsWith("/api/auth/refresh");
    }
}
