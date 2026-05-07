package com.tutict.finalassignmentbackend.ai.provider;

import java.util.Map;

public record AiChatPrompt(
        String message,
        Map<String, Object> metadata
) {
    public AiChatPrompt {
        metadata = metadata == null ? Map.of() : Map.copyOf(metadata);
    }
}
