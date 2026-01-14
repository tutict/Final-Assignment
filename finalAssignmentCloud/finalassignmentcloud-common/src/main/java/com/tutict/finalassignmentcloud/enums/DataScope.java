package com.tutict.finalassignmentcloud.enums;

import lombok.Getter;

/**
 * 数据权限范围枚举
 * 定义角色可以访问的数据范围
 */
@Getter
public enum DataScope {
    /**
     * 全部数据权限 - 可以访问系统中的所有数据
     */
    ALL("All", "全部数据权限"),

    /**
     * 本部门数据权限 - 只能访问所属部门的数据
     */
    DEPARTMENT("Department", "本部门数据权限"),

    /**
     * 本部门及以下数据权限 - 可以访问所属部门及其下级部门的数据
     */
    DEPARTMENT_AND_SUB("Department_And_Sub", "本部门及以下数据权限"),

    /**
     * 仅本人数据权限 - 只能访问自己创建或负责的数据
     */
    SELF("Self", "仅本人数据权限"),

    /**
     * 自定义数据权限 - 自定义数据权限范围
     */
    CUSTOM("Custom", "自定义数据权限");

    private final String code;
    private final String description;

    DataScope(String code, String description) {
        this.code = code;
        this.description = description;
    }

    /**
     * 根据代码获取数据权限范围
     *
     * @param code 数据权限代码
     * @return 数据权限枚举，如果未找到则返回 null
     */
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

    /**
     * 验证给定的代码是否为有效的数据权限范围
     *
     * @param code 数据权限代码
     * @return 如果代码有效则返回 true，否则返回 false
     */
    public static boolean isValid(String code) {
        return fromCode(code) != null;
    }

    /**
     * 检查当前权限范围是否包含指定的权限范围
     * 权限包含关系：ALL > DEPARTMENT_AND_SUB > DEPARTMENT > SELF > CUSTOM
     *
     * @param other 要比较的权限范围
     * @return 如果当前权限包含指定权限则返回 true
     */
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