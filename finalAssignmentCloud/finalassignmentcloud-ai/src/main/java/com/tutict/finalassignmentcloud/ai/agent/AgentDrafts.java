package com.tutict.finalassignmentcloud.ai.agent;

import com.tutict.finalassignmentcloud.model.ai.ChatAction;

import java.time.Duration;
import java.time.Instant;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.UUID;

public final class AgentDrafts {

    private AgentDrafts() {
    }

    public static AgentDraft create(
            AgentToolContext context,
            AgentTool tool,
            String summary,
            Map<String, Object> preview,
            Map<String, Object> payload
    ) {
        Instant now = Instant.now();
        return new AgentDraft(
                UUID.randomUUID().toString(),
                context.userKey(),
                context.sessionKey(),
                tool.name(),
                tool.serviceName(),
                tool.risk(),
                summary,
                preview == null ? Map.of() : preview,
                payload == null ? Map.of() : payload,
                now,
                now.plus(Duration.ofMinutes(10))
        );
    }

    public static ChatAction navigate(String label, String target) {
        return new ChatAction("NAVIGATE", label, target, "{\"source\":\"agent_tool\"}");
    }

    public static Map<String, Object> schema(String... required) {
        Map<String, Object> properties = new LinkedHashMap<>();
        properties.put("query", Map.of("type", "string", "description", "可选过滤关键字"));
        properties.put("id", Map.of("type", "integer", "description", "可选业务 ID"));
        properties.put("page", Map.of("type", "integer"));
        properties.put("size", Map.of("type", "integer"));
        Map<String, Object> schema = new LinkedHashMap<>();
        schema.put("type", "object");
        schema.put("properties", properties);
        if (required != null && required.length > 0) {
            schema.put("required", required);
        }
        return schema;
    }
}
