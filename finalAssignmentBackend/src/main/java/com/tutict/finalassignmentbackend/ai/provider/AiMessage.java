package com.tutict.finalassignmentbackend.ai.provider;

import java.util.Map;

public record AiMessage(
        String text,
        Map<String, Object> metadata
) {
    public AiMessage {
        text = text == null ? "" : text;
        metadata = metadata == null ? Map.of() : Map.copyOf(metadata);
    }
}
