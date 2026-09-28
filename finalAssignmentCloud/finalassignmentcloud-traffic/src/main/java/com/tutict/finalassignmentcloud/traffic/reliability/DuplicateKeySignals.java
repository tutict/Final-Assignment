package com.tutict.finalassignmentcloud.traffic.reliability;

public final class DuplicateKeySignals {

    private DuplicateKeySignals() {
    }

    public static boolean duplicateKey(Throwable error) {
        Throwable current = error;
        while (current != null) {
            String name = current.getClass().getName();
            if (name.contains("DuplicateKey") || name.contains("SQLIntegrityConstraintViolation")) {
                return true;
            }
            String message = current.getMessage();
            if (message != null && message.contains("Duplicate entry")) {
                return true;
            }
            current = current.getCause();
        }
        return false;
    }
}