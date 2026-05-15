package com.tutict.finalassignmentbackend.ai.chat;

import com.fasterxml.jackson.annotation.JsonIgnore;

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

    @JsonIgnore
    public boolean isWebSearchEnabled() {
        Object val = metadata.get("webSearchRequested");
        if (val == null) {
            val = metadata.get("webSearch");
        }
        if (val == null) {
            val = metadata.get("web_search");
        }
        if (val instanceof Boolean enabled) {
            return enabled;
        }
        if (val instanceof String text) {
            return Boolean.parseBoolean(text);
        }
        return false;
    }
}
