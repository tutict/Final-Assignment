package com.tutict.finalassignmentbackend.ai.provider;

import java.time.Instant;
import java.util.Map;

public record ProviderHealth(
        String status,
        String message,
        Map<String, Object> metadata,
        Instant timestamp
) {
    public ProviderHealth {
        status = status == null || status.isBlank() ? "UNKNOWN" : status;
        message = message == null ? "" : message;
        metadata = metadata == null ? Map.of() : Map.copyOf(metadata);
        timestamp = timestamp == null ? Instant.now() : timestamp;
    }

    public static ProviderHealth up(String message) {
        return new ProviderHealth("UP", message, Map.of(), Instant.now());
    }

    public static ProviderHealth down(String message) {
        return new ProviderHealth("DOWN", message, Map.of(), Instant.now());
    }
}
