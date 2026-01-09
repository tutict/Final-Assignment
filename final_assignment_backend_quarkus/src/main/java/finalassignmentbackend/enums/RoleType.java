package finalassignmentbackend.enums;

import lombok.Getter;

/**
 * Role types for access control.
 */
@Getter
public enum RoleType {
    SYSTEM("System", "System role"),
    BUSINESS("Business", "Business role"),
    CUSTOM("Custom", "Custom role");

    private final String code;
    private final String description;

    RoleType(String code, String description) {
        this.code = code;
        this.description = description;
    }

    public static RoleType fromCode(String code) {
        if (code == null) {
            return null;
        }
        for (RoleType type : values()) {
            if (type.code.equalsIgnoreCase(code)) {
                return type;
            }
        }
        return null;
    }

    public static boolean isValid(String code) {
        return fromCode(code) != null;
    }
}
