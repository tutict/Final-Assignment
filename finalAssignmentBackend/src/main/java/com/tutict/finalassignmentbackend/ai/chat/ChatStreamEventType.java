package com.tutict.finalassignmentbackend.ai.chat;

import java.util.Locale;

public enum ChatStreamEventType {
    SESSION,
    TOKEN,
    DONE,
    ERROR,
    USAGE,
    KEEPALIVE,
    TOOL,
    RESULT,
    DRAFT,
    ACTION;

    public String wireName() {
        return name().toLowerCase(Locale.ROOT);
    }
}
