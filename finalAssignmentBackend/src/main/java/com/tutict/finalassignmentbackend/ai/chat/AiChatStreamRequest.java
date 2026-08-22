package com.tutict.finalassignmentbackend.ai.chat;

import com.fasterxml.jackson.annotation.JsonIgnore;

import java.util.Collection;
import java.util.Map;

public record AiChatStreamRequest(
        String message,
        String sessionKey,
        Map<String, Object> metadata
) {
    // Max lengths enforced at the controller boundary
    public static final int MAX_MESSAGE_LENGTH = 10000;
    public static final int MAX_SESSION_KEY_LENGTH = 128;
    public static final int MAX_METADATA_JSON_SIZE = 2048;
    public static final int MAX_CONVERSATION_WINDOW_TURNS = 20;

    public AiChatStreamRequest {
        if (metadata == null) {
            metadata = Map.of();
        }
        if (message != null && message.length() > MAX_MESSAGE_LENGTH) {
            message = message.substring(0, MAX_MESSAGE_LENGTH);
        }
        if (sessionKey != null && sessionKey.length() > MAX_SESSION_KEY_LENGTH) {
            sessionKey = sessionKey.substring(0, MAX_SESSION_KEY_LENGTH);
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
