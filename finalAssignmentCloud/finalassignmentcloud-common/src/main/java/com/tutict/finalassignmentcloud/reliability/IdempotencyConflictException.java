package com.tutict.finalassignmentcloud.reliability;

public class IdempotencyConflictException extends RuntimeException {

    public IdempotencyConflictException() {
    }

    public IdempotencyConflictException(String message) {
        super(message);
    }
}
