package com.tutict.finalassignmentbackend.reliability;

public final class LoadShedPolicy {

    public static boolean shed(String method, String path, double utilization, int awaitingConnections, int idleConnections) {
        if (path == null || isHealth(path)) {
            return false;
        }
        String verb = method == null ? "" : method.toUpperCase();
        boolean ledger = isLedger(path);
        if (isLedgerWrite(verb, ledger)) {
            return awaitingConnections > 0 || (utilization >= 0.8d && idleConnections <= 0);
        }
        return "GET".equals(verb) && !ledger && utilization >= 0.8d;
    }


    public static boolean shedWhenBusy(String method, String path, int inFlight, int maxPool) {
        if (maxPool <= 0 || inFlight <= maxPool || path == null || isHealth(path)) {
            return false;
        }
        String verb = method == null ? "" : method.toUpperCase();
        boolean ledger = isLedger(path);
        if (isLedgerWrite(verb, ledger)) {
            return true;
        }
        return "GET".equals(verb) && !ledger;
    }
    private static boolean isLedgerWrite(String verb, boolean ledger) {
        return ledger && ("POST".equals(verb) || "PUT".equals(verb) || "DELETE".equals(verb));
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
                || path.startsWith("/q/health")
                || path.startsWith("/api/actuator/health");
    }
}