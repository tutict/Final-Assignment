package finalassignmentbackend.config.statemachine.events;

/**
 * Events that drive offense process state transitions.
 */
public enum OffenseProcessEvent {
    START_PROCESSING,
    COMPLETE_PROCESSING,
    SUBMIT_APPEAL,
    APPROVE_APPEAL,
    REJECT_APPEAL,
    CANCEL,
    WITHDRAW_APPEAL
}
