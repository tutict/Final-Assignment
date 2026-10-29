package finalassignmentbackend.ai.chat;

import java.time.Instant;
import java.util.LinkedHashMap;
import java.util.Map;

/**
 * One SSE frame of the chat stream. Field names match the Spring and Go backends so the same
 * frontend and evaluation harness can parse all three.
 */
public record ChatStreamEvent(
        String type,
        String sessionKey,
        String messageId,
        String token,
        Object payload,
        String timestamp
) {

    public static ChatStreamEvent token(String sessionKey, String messageId, String token) {
        return new ChatStreamEvent("token", sessionKey, messageId, token, null, Instant.now().toString());
    }

    public static ChatStreamEvent control(String type, String sessionKey, String messageId, Object payload) {
        return new ChatStreamEvent(type, sessionKey, messageId, null, payload, Instant.now().toString());
    }

    public static ChatStreamEvent done(String sessionKey, String messageId) {
        return new ChatStreamEvent("done", sessionKey, messageId, null, null, Instant.now().toString());
    }

    public static ChatStreamEvent keepalive(String sessionKey, String messageId) {
        return new ChatStreamEvent("keepalive", sessionKey, messageId, null, null, Instant.now().toString());
    }

    public static ChatStreamEvent error(String sessionKey, String messageId, String message) {
        String text = message == null || message.isBlank() ? "AI stream failed" : message;
        return control("error", sessionKey, messageId, Map.of("message", text));
    }

    public static ChatStreamEvent fromAgentEvent(Map<String, Object> event, String sessionKey, String messageId) {
        String type = String.valueOf(event.getOrDefault("type", "unknown"));
        Object payload = event.get("payload");
        Object timestamp = event.get("timestamp");
        return new ChatStreamEvent(type, sessionKey, messageId, null, payload,
                timestamp == null ? Instant.now().toString() : String.valueOf(timestamp));
    }

    public Map<String, Object> toMap() {
        Map<String, Object> map = new LinkedHashMap<>();
        map.put("type", type);
        if (sessionKey != null) {
            map.put("sessionKey", sessionKey);
        }
        if (messageId != null) {
            map.put("messageId", messageId);
        }
        if (token != null) {
            map.put("token", token);
        }
        if (payload != null) {
            map.put("payload", payload);
        }
        map.put("timestamp", timestamp == null ? Instant.now().toString() : timestamp);
        return map;
    }
}
