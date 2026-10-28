package com.tutict.finalassignmentbackend.ai.provider;

import java.time.Duration;
import java.util.Map;

public record AiGenerationOptions(
        Duration timeout,
        Duration streamingTimeout,
        int retryAttempts,
        Double temperature,
        Integer maxTokens,
        String model,
        Map<String, Object> responseFormat,
        Map<String, Object> metadata
) {
    public AiGenerationOptions {
        timeout = timeout == null ? Duration.ofSeconds(60) : timeout;
        streamingTimeout = streamingTimeout == null ? Duration.ofSeconds(180) : streamingTimeout;
        retryAttempts = Math.max(0, retryAttempts);
        metadata = metadata == null ? Map.of() : Map.copyOf(metadata);
    }

    public AiGenerationOptions(
            Duration timeout,
            Duration streamingTimeout,
            int retryAttempts,
            Double temperature,
            Integer maxTokens,
            Map<String, Object> metadata
    ) {
        this(timeout, streamingTimeout, retryAttempts, temperature, maxTokens, null, null, metadata);
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

    /**
     * Guardrail judgements are single-shot: retrying doubles latency, and a verdict produced at a
     * higher temperature is not reproducible. The model and response schema are chosen explicitly
     * so verification neither inherits the chat model nor relies on the model echoing a key name.
     */
    public static AiGenerationOptions forVerification(
            Duration timeout,
            String model,
            Map<String, Object> responseFormat
    ) {
        return new AiGenerationOptions(timeout, timeout, 0, 0.0, 96, model, responseFormat, Map.of());
    }
}
