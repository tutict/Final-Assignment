package finalassignmentbackend.config.statemachine.events;

/**
 * Events that drive payment state transitions.
 */
public enum PaymentEvent {
    PARTIAL_PAY,
    COMPLETE_PAYMENT,
    MARK_OVERDUE,
    WAIVE_FINE,
    CONTINUE_PAYMENT
}
