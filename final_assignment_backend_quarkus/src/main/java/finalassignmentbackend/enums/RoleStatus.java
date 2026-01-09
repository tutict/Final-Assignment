package finalassignmentbackend.enums;

import lombok.Getter;

/**
 * Role status enumeration.
 */
@Getter
public enum RoleStatus {
    ACTIVE("Active", "Active"),
    INACTIVE("Inactive", "Inactive");

    private final String code;
    private final String description;

    RoleStatus(String code, String description) {
        this.code = code;
        this.description = description;
    }

    public static RoleStatus fromCode(String code) {
        if (code == null) {
            return null;
        }
        for (RoleStatus status : values()) {
            if (status.code.equalsIgnoreCase(code)) {
                return status;
            }
        }
        return null;
    }

    public static boolean isValid(String code) {
        return fromCode(code) != null;
    }

    public boolean isActive() {
        return this == ACTIVE;
    }
}
