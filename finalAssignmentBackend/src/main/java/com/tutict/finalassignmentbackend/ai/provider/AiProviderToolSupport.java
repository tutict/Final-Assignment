package com.tutict.finalassignmentbackend.ai.provider;

import com.fasterxml.jackson.databind.JsonNode;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

public final class AiProviderToolSupport {

    private AiProviderToolSupport() {
    }

    @SuppressWarnings("unchecked")
    public static List<Map<String, Object>> messagesFrom(AiChatPrompt prompt) {
        Object raw = prompt.metadata().get("messages");
        if (raw instanceof List<?> list && !list.isEmpty()) {
            List<Map<String, Object>> messages = new ArrayList<>();
            for (Object item : list) {
                if (item instanceof Map<?, ?> map) {
                    Map<String, Object> copy = new LinkedHashMap<>();
                    map.forEach((k, v) -> copy.put(String.valueOf(k), v));
                    messages.add(copy);
                }
            }
            if (!messages.isEmpty()) {
                return messages;
            }
        }
        return List.of(Map.of("role", "user", "content", prompt.message() == null ? "" : prompt.message()));
    }

    @SuppressWarnings("unchecked")
    public static List<Map<String, Object>> toolsFrom(AiChatPrompt prompt) {
        Object raw = prompt.metadata().get("tools");
        if (!(raw instanceof List<?> list) || list.isEmpty()) {
            return List.of();
        }
        List<Map<String, Object>> tools = new ArrayList<>();
        for (Object item : list) {
            if (item instanceof Map<?, ?> map) {
                Map<String, Object> copy = new LinkedHashMap<>();
                map.forEach((k, v) -> copy.put(String.valueOf(k), v));
                tools.add(copy);
            }
        }
        return tools;
    }

    public static boolean hasToolMessages(AiChatPrompt prompt) {
        for (Map<String, Object> message : messagesFrom(prompt)) {
            if ("tool".equals(String.valueOf(message.get("role")))) {
                return true;
            }
        }
        return false;
    }

    public static String lastUserContent(AiChatPrompt prompt) {
        List<Map<String, Object>> messages = messagesFrom(prompt);
        for (int i = messages.size() - 1; i >= 0; i--) {
            if ("user".equals(String.valueOf(messages.get(i).get("role")))) {
                return String.valueOf(messages.get(i).getOrDefault("content", prompt.message()));
            }
        }
        return prompt.message() == null ? "" : prompt.message();
    }

    public static List<Map<String, Object>> parseToolCalls(JsonNode node) {
        List<Map<String, Object>> calls = new ArrayList<>();
        JsonNode message = node.path("message");
        JsonNode toolCalls = message.path("tool_calls");
        if (!toolCalls.isArray() || toolCalls.isEmpty()) {
            toolCalls = node.path("choices").path(0).path("delta").path("tool_calls");
        }
        if (!toolCalls.isArray() || toolCalls.isEmpty()) {
            toolCalls = node.path("choices").path(0).path("message").path("tool_calls");
        }
        if (!toolCalls.isArray()) {
            return calls;
        }
        for (JsonNode call : toolCalls) {
            Map<String, Object> parsed = new LinkedHashMap<>();
            parsed.put("id", call.path("id").asText(""));
            String name = call.path("function").path("name").asText(call.path("name").asText(""));
            parsed.put("name", name);
            JsonNode args = call.path("function").path("arguments");
            if (args.isMissingNode() || args.isNull()) {
                args = call.path("arguments");
            }
            parsed.put("arguments", args.isTextual() || args.isMissingNode() ? args.asText("{}") : args.toString());
            if (!name.isBlank()) {
                calls.add(parsed);
            }
        }
        return calls;
    }
}
