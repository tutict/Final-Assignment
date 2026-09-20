package com.tutict.finalassignmentbackend.ai.chat;

import java.time.Duration;

public class AiRateLimitException extends AiQueueException {

    private final Duration retryAfter;

    public AiRateLimitException(Duration retryAfter) {
        super("上游接口繁忙，请稍后再试");
        this.retryAfter = retryAfter == null || retryAfter.isNegative() || retryAfter.isZero()
                ? Duration.ofSeconds(1)
                : retryAfter;
    }

    public Duration retryAfter() {
        return retryAfter;
    }
}
