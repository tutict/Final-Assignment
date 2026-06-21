package com.tutict.finalassignmentcloud.ai.provider;

import java.util.LinkedHashMap;
import java.util.Map;

public record AiToken(
        String text,
        boolean finished,
        Map<String, Object> metadata
) {
    public AiToken {
        text = text == null ? "" : text;
        metadata = metadata == null ? Map.of() : Map.copyOf(metadata);
    }

    public AiToken withMetadata(String key, Object value) {
        Map<String, Object> merged = new LinkedHashMap<>(metadata);
        if (value != null) {
            merged.put(key, value);
        }
        return new AiToken(text, finished, merged);
    }
}
