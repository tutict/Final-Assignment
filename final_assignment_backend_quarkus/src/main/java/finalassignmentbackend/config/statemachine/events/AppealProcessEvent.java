package finalassignmentbackend.config.statemachine.events;

/**
 * Events that drive appeal process state transitions.
 */
public enum AppealProcessEvent {
    START_REVIEW,
    APPROVE,
    REJECT,
    WITHDRAW,
    REOPEN_REVIEW
}
