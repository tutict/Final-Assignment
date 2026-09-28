package finalassignmentbackend.reliability;

public final class BlacklistAccessPolicy {
    public enum Verdict { CLEAR, REVOKED, UNAVAILABLE }
    public enum Effect { ALLOW, DENY, SHED }

    private BlacklistAccessPolicy() {}

    public static Effect decide(String method, String path, Verdict verdict) {
        if (verdict == Verdict.REVOKED) {
            return Effect.DENY;
        }
        if (verdict != Verdict.UNAVAILABLE) {
            return Effect.ALLOW;
        }
        String verb = method == null ? "" : method.toUpperCase();
        boolean write = verb.equals("POST") || verb.equals("PUT") || verb.equals("PATCH") || verb.equals("DELETE");
        boolean login = path != null && (path.contains("api/auth/login") || path.contains("api/auth/refresh"));
        return write || login ? Effect.SHED : Effect.ALLOW;
    }
}
