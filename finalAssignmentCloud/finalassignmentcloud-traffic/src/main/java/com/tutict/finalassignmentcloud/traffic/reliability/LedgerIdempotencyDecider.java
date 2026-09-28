package com.tutict.finalassignmentcloud.traffic.reliability;

import java.time.Duration;

public final class LedgerIdempotencyDecider {

    public static final Duration PROCESSING_TTL = Duration.ofMinutes(2);

    public enum Outcome {
        INSERT, REPLAY, CONFLICT, IN_PROGRESS, RETRY
    }

    private LedgerIdempotencyDecider() {
    }

    public static Outcome decide(boolean exists, String status, String storedParams, String incomingFingerprint, Duration age) {
        if (!exists) {
            return Outcome.INSERT;
        }
        String normalized = status == null ? "" : status.trim();
        if ("FAILED".equalsIgnoreCase(normalized)) {
            return Outcome.RETRY;
        }
        if ("PROCESSING".equalsIgnoreCase(normalized)) {
            return (age != null && age.compareTo(PROCESSING_TTL) >= 0) ? Outcome.RETRY : Outcome.IN_PROGRESS;
        }
        if ("SUCCESS".equalsIgnoreCase(normalized)) {
            return samePayload(storedParams, incomingFingerprint) ? Outcome.REPLAY : Outcome.CONFLICT;
        }
        return Outcome.CONFLICT;
    }

    private static boolean samePayload(String storedParams, String incomingFingerprint) {
        if (incomingFingerprint == null || incomingFingerprint.isBlank()) {
            return true;
        }
        if (storedParams == null || storedParams.isBlank() || "DONE".equalsIgnoreCase(storedParams)) {
            return true;
        }
        return storedParams.equals(incomingFingerprint);
    }
}