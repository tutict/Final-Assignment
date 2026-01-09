package finalassignmentbackend.enums;

import lombok.Getter;

/**
 * Data scope for role-based access control.
 */
@Getter
public enum DataScope {
    ALL("All", "All data"),
    DEPARTMENT("Department", "Department data"),
    DEPARTMENT_AND_SUB("Department_And_Sub", "Department and sub-department data"),
    SELF("Self", "Self data"),
    CUSTOM("Custom", "Custom data scope");

    private final String code;
    private final String description;

    DataScope(String code, String description) {
        this.code = code;
        this.description = description;
    }

    public static DataScope fromCode(String code) {
        if (code == null) {
            return null;
        }
        for (DataScope scope : values()) {
            if (scope.code.equalsIgnoreCase(code)) {
                return scope;
            }
        }
        return null;
    }

    public static boolean isValid(String code) {
        return fromCode(code) != null;
    }

    public boolean includes(DataScope other) {
        if (this == ALL) {
            return true;
        }
        if (this == DEPARTMENT_AND_SUB) {
            return other == DEPARTMENT || other == SELF || other == DEPARTMENT_AND_SUB;
        }
        if (this == DEPARTMENT) {
            return other == SELF || other == DEPARTMENT;
        }
        return this == other;
    }
}
