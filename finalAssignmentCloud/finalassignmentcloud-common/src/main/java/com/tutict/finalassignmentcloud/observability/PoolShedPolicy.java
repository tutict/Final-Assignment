package com.tutict.finalassignmentcloud.observability;

public final class PoolShedPolicy {

    private PoolShedPolicy() {
    }

    public static boolean shed(String method, String path, double utilization, int awaitingConnections,
                               int idleConnections, int maxPoolSize) {
        if (path == null || isHealth(path)) {
            return false;
        }
        String verb = method == null ? "" : method.toUpperCase();
        boolean ledger = isLedger(path);
        if (ledger && ("POST".equals(verb) || "PUT".equals(verb) || "DELETE".equals(verb))) {
            return awaitingConnections > 0 || (utilization >= 0.8d && idleConnections <= 0);
        }
        // Utilization and servlet in-flight counts both stay high for a healthy pool that is
        // simply busy. Shed only once the queue is deep enough to signal sustained overload,
        // so a burst that the pool can still drain is left to queue.
        int queueTolerance = Math.max(1, maxPoolSize / 2);
        return "GET".equals(verb) && !ledger && awaitingConnections >= queueTolerance;
    }

    private static boolean isLedger(String path) {
        String value = path.startsWith("/") ? path : "/" + path;
        return value.startsWith("/api/payments")
                || value.startsWith("/api/fines")
                || value.startsWith("/api/deductions")
                || value.startsWith("/api/appeals")
                || value.startsWith("/api/offenses");
    }

    private static boolean isHealth(String path) {
        return path.startsWith("/actuator/health")
                || path.startsWith("/api/actuator/health")
                || path.startsWith("/q/health");
    }
}
