package com.tutict.finalassignmentbackend.ai.chat;

import java.util.Locale;

public enum ChatStreamEventType {
    SESSION,
    TOKEN,
    DONE,
    ERROR,
    USAGE,
    KEEPALIVE;

    public String wireName() {
        return name().toLowerCase(Locale.ROOT);
    }
}
