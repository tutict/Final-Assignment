package com.tutict.finalassignmentcloud.traffic.reliability;

public final class LedgerKeyPolicy {

    private LedgerKeyPolicy() {
    }

    public static boolean requiresKey(String method, String path) {
        if (method == null || path == null) {
            return false;
        }
        String normalized = path.startsWith("/") ? path : "/" + path;
        String verb = method.toUpperCase();
        if ("POST".equals(verb)) {
            return normalized.equals("/api/payments")
                    || normalized.equals("/api/fines")
                    || normalized.equals("/api/deductions")
                    || normalized.equals("/api/appeals")
                    || normalized.matches("/api/appeals/\\d+/reviews")
                    || normalized.matches("/api/workflow/payments/\\d+/events/[A-Za-z0-9_-]+")
                    || normalized.matches("/api/workflow/appeals/\\d+/events/[A-Za-z0-9_-]+");
        }
        return "PUT".equals(verb) && (normalized.matches("/api/appeals/\\d+") || normalized.matches("/api/appeals/reviews/\\d+"));
    }
}
