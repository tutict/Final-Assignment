package com.tutict.finalassignmentcloud.observability;

public final class LedgerConnectionSignals {

    private LedgerConnectionSignals() {
    }

    public static boolean ledgerWrite(String method, String path) {
        if (method == null || path == null) {
            return false;
        }
        String verb = method.toUpperCase();
        if (!verb.equals("POST") && !verb.equals("PUT") && !verb.equals("DELETE")) {
            return false;
        }
        String value = path.startsWith("/") ? path : "/" + path;
        return value.startsWith("/api/payments")
                || value.startsWith("/api/fines")
                || value.startsWith("/api/deductions")
                || value.startsWith("/api/appeals")
                || value.startsWith("/api/offenses");
    }

    public static boolean connectionWait(Throwable failure) {
        Throwable current = failure;
        while (current != null) {
            String name = current.getClass().getName();
            if (name.endsWith("SQLTransientConnectionException")
                    || name.endsWith("CannotGetJdbcConnectionException")) {
                return true;
            }
            String message = current.getMessage();
            if (message != null && (message.contains("Connection is not available")
                    || message.contains("request timed out after")
                    || message.contains("Acquisition timeout")
                    || message.contains("timeout waiting for connection"))) {
                return true;
            }
            current = current.getCause();
        }
        return false;
    }
}
