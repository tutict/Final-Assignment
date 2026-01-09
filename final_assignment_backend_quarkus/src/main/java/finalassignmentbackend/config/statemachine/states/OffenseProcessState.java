package finalassignmentbackend.config.statemachine.states;

import lombok.Getter;

/**
 * Offense processing states.
 */
@Getter
public enum OffenseProcessState {
    UNPROCESSED("Unprocessed", "Unprocessed"),
    PROCESSING("Processing", "Processing"),
    PROCESSED("Processed", "Processed"),
    APPEALING("Appealing", "Appealing"),
    APPEAL_APPROVED("Appeal_Approved", "Appeal approved"),
    APPEAL_REJECTED("Appeal_Rejected", "Appeal rejected"),
    CANCELLED("Cancelled", "Cancelled");

    private final String code;
    private final String description;

    OffenseProcessState(String code, String description) {
        this.code = code;
        this.description = description;
    }

    public static OffenseProcessState fromCode(String code) {
        if (code == null) {
            return null;
        }
        for (OffenseProcessState state : values()) {
            if (state.code.equalsIgnoreCase(code)) {
                return state;
            }
        }
        return null;
    }
}
