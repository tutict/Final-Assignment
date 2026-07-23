package com.tutict.finalassignmentbackend.appeal.domain.idempotency;

/** Signals that an appeal create key has already been reserved or completed. */
public class AppealDuplicateRequestException extends RuntimeException {

    public AppealDuplicateRequestException(String message) {
        super(message);
    }

    public AppealDuplicateRequestException(String message, Throwable cause) {
        super(message, cause);
    }
}
