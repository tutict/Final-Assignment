package finalassignmentbackend.reliability;

public class IdempotencyReplayException extends RuntimeException {
    public IdempotencyReplayException() {
        super("duplicate ledger request");
    }
}