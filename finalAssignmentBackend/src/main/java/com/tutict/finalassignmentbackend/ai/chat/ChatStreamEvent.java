package com.tutict.finalassignmentbackend.ai.chat;

import java.time.Instant;
import java.util.Map;

public record ChatStreamEvent(
        String type,
        String sessionKey,
        String messageId,
        String token,
        Object payload,
        Instant timestamp
) {
    public static ChatStreamEvent session(String sessionKey, String messageId, Object payload) {
        return new ChatStreamEvent(
                ChatStreamEventType.SESSION.wireName(),
                sessionKey,
                messageId,
                null,
                payload,
                Instant.now()
        );
    }

    public static ChatStreamEvent token(String sessionKey, String messageId, String token) {
        return new ChatStreamEvent(
                ChatStreamEventType.TOKEN.wireName(),
                sessionKey,
                messageId,
                token,
                null,
                Instant.now()
        );
    }

    public static ChatStreamEvent done(String sessionKey, String messageId) {
        return new ChatStreamEvent(
                ChatStreamEventType.DONE.wireName(),
                sessionKey,
                messageId,
                null,
                null,
                Instant.now()
        );
    }

    public static ChatStreamEvent error(String sessionKey, String messageId, String message) {
        String errorMessage = message == null || message.isBlank()
                ? "AI stream failed"
                : message;
        return new ChatStreamEvent(
                ChatStreamEventType.ERROR.wireName(),
                sessionKey,
                messageId,
                null,
                Map.of("message", errorMessage),
                Instant.now()
        );
    }

    public static ChatStreamEvent keepalive(String sessionKey, String messageId) {
        return new ChatStreamEvent(
                ChatStreamEventType.KEEPALIVE.wireName(),
                sessionKey,
                messageId,
                null,
                null,
                Instant.now()
        );
    }
}
