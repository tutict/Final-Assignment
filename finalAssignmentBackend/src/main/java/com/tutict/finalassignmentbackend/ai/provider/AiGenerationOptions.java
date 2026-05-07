package com.tutict.finalassignmentbackend.ai.provider;

import java.time.Duration;
import java.util.Map;

public record AiGenerationOptions(
        Duration timeout,
        Duration streamingTimeout,
        int retryAttempts,
        Double temperature,
        Integer maxTokens,
        Map<String, Object> metadata
) {
    public AiGenerationOptions {
        timeout = timeout == null ? Duration.ofSeconds(60) : timeout;
        streamingTimeout = streamingTimeout == null ? Duration.ofSeconds(180) : streamingTimeout;
        retryAttempts = Math.max(0, retryAttempts);
        metadata = metadata == null ? Map.of() : Map.copyOf(metadata);
    }

    public static AiGenerationOptions from(AiProviderProperties properties, Map<String, Object> metadata) {
        return new AiGenerationOptions(
                properties.getProvider().getTimeout(),
                properties.getProvider().getStreamingTimeout(),
                properties.getProvider().getRetryAttempts(),
                null,
                null,
                metadata
        );
    }
}
