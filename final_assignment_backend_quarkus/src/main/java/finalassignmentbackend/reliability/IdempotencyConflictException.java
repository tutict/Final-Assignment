package finalassignmentbackend.reliability;

public class IdempotencyConflictException extends RuntimeException {
    public IdempotencyConflictException() {
        super("Idempotency-Key was reused with a different payload");
    }
}
