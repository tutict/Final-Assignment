package com.tutict.finalassignmentbackend.ai.chat;

import java.time.Instant;

public record AiChatStreamResponse(
        String sessionKey,
        String messageId,
        String status,
        Instant timestamp
) {
    public static AiChatStreamResponse opened(String sessionKey, String messageId) {
        return new AiChatStreamResponse(sessionKey, messageId, "opened", Instant.now());
    }
}
