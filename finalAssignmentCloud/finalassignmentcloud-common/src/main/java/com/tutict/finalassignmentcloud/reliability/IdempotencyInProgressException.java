package com.tutict.finalassignmentcloud.reliability;

public class IdempotencyInProgressException extends RuntimeException {

    public IdempotencyInProgressException() {
    }

    public IdempotencyInProgressException(String message) {
        super(message);
    }
}
