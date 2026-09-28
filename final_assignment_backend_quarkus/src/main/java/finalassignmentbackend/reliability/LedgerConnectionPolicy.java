package finalassignmentbackend.reliability;

public final class LedgerConnectionPolicy {

    private LedgerConnectionPolicy() {
    }

    public static boolean connectionWaitOnLedgerWrite(String method, String path) {
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
                || value.startsWith("/api/offenses")
                || value.startsWith("/api/workflow/payments")
                || value.startsWith("/api/workflow/appeals");
    }

    public static boolean connectionWait(Throwable failure) {
        Throwable current = failure;
        while (current != null) {
            String name = current.getClass().getName();
            if (name.endsWith("SQLTransientConnectionException")
                    || name.endsWith("CannotGetJdbcConnectionException")) {
                return true;
            }
            if (current instanceof java.sql.SQLException sql) {
                String state = sql.getSQLState();
                int code = sql.getErrorCode();
                if ("40001".equals(state) || "08S01".equals(state) || "08001".equals(state)
                        || code == 1205 || code == 1213) {
                    return true;
                }
            }
            String message = current.getMessage();
            if (message != null && (message.contains("Acquisition timeout")
                    || message.contains("Connection is not available")
                    || message.contains("timeout waiting for connection")
                    || message.contains("Lock wait timeout")
                    || message.contains("Deadlock found")
                    || message.contains("connection reset")
                    || message.contains("broken pipe"))) {
                return true;
            }
            if (name.endsWith("TimeoutException")
                    || name.endsWith("SQLTransientException")
                    || name.endsWith("ConnectionPoolTooBusyException")) {
                return true;
            }
            current = current.getCause();
        }
        return false;
    }
}
