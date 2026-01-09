package finalassignmentbackend.config.statemachine.states;

import lombok.Getter;

/**
 * Payment states.
 */
@Getter
public enum PaymentState {
    UNPAID("Unpaid", "Unpaid"),
    PARTIAL("Partial", "Partial"),
    PAID("Paid", "Paid"),
    OVERDUE("Overdue", "Overdue"),
    WAIVED("Waived", "Waived");

    private final String code;
    private final String description;

    PaymentState(String code, String description) {
        this.code = code;
        this.description = description;
    }

    public static PaymentState fromCode(String code) {
        if (code == null) {
            return null;
        }
        for (PaymentState state : values()) {
            if (state.code.equalsIgnoreCase(code)) {
                return state;
            }
        }
        return null;
    }
}
