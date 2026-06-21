package com.tutict.finalassignmentcloud.ai.chat.response;

/**
 * Chat Stream Event
 * Represents an event in the chat stream
 */
public record ChatStreamEvent(String type, Object payload) {

    public static ChatStreamEvent token(String token) {
        return new ChatStreamEvent("token", token);
    }

    public static ChatStreamEvent done() {
        return new ChatStreamEvent("done", null);
    }

    public static ChatStreamEvent error(String message) {
        return new ChatStreamEvent("error", message);
    }
}