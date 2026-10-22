package com.tutict.finalassignmentcloud.reliability;

public class IdempotencyReplayException extends RuntimeException {

    public IdempotencyReplayException() {
    }

    public IdempotencyReplayException(String message) {
        super(message);
    }
}
