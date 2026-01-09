package finalassignmentbackend.config.statemachine.states;

import lombok.Getter;

/**
 * Appeal processing states.
 */
@Getter
public enum AppealProcessState {
    UNPROCESSED("Unprocessed", "Unprocessed"),
    UNDER_REVIEW("Under_Review", "Under review"),
    APPROVED("Approved", "Approved"),
    REJECTED("Rejected", "Rejected"),
    WITHDRAWN("Withdrawn", "Withdrawn");

    private final String code;
    private final String description;

    AppealProcessState(String code, String description) {
        this.code = code;
        this.description = description;
    }

    public static AppealProcessState fromCode(String code) {
        if (code == null) {
            return null;
        }
        for (AppealProcessState state : values()) {
            if (state.code.equalsIgnoreCase(code)) {
                return state;
            }
        }
        return null;
    }
}
