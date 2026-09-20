package com.tutict.finalassignmentbackend.ai.agent;

import java.util.Map;

public record AgentToolCall(
        String id,
        String name,
        Map<String, Object> arguments
) {
    public AgentToolCall {
        id = id == null || id.isBlank() ? java.util.UUID.randomUUID().toString() : id;
        name = name == null ? "" : name;
        arguments = arguments == null ? Map.of() : Map.copyOf(arguments);
    }
}
