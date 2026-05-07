package com.tutict.finalassignmentbackend.ai.chat;

import java.util.Map;

public record AiChatStreamRequest(
        String message,
        String sessionKey,
        Map<String, Object> metadata
) {
    public AiChatStreamRequest {
        if (metadata == null) {
            metadata = Map.of();
        }
    }

    public boolean hasMessage() {
        return message != null && !message.isBlank();
    }

    public String normalizedMessage() {
        return hasMessage() ? message.trim() : "";
    }
}
