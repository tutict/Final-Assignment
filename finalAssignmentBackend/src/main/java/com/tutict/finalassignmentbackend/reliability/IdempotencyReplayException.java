package com.tutict.finalassignmentbackend.reliability;

public class IdempotencyReplayException extends RuntimeException {
    public IdempotencyReplayException(String message) {
        super(message);
    }
}
