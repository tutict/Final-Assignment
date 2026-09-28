package finalassignmentbackend.reliability;

public class IdempotencyInProgressException extends RuntimeException {
    public IdempotencyInProgressException() {
        super("Idempotency-Key is already in progress");
    }
}