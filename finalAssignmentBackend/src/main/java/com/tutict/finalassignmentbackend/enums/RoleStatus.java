package com.tutict.finalassignmentbackend.enums;

import lombok.Getter;

/**
 * 角色状态枚举
 * 定义角色的启用/禁用状态
 */
@Getter
public enum RoleStatus {
    /**
     * 启用状态 - 角色可以正常使用
     */
    ACTIVE("Active", "启用"),

    /**
     * 禁用状态 - 角色被禁用，不能使用
     */
    INACTIVE("Inactive", "禁用");

    private final String code;
    private final String description;

    RoleStatus(String code, String description) {
        this.code = code;
        this.description = description;
    }

    /**
     * 根据代码获取角色状态
     *
     * @param code 状态代码
     * @return 角色状态枚举，如果未找到则返回 null
     */
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

    /**
     * 验证给定的代码是否为有效的角色状态
     *
     * @param code 状态代码
     * @return 如果代码有效则返回 true，否则返回 false
     */
    public static boolean isValid(String code) {
        return fromCode(code) != null;
    }

    /**
     * 检查角色是否处于激活状态
     *
     * @return 如果角色处于激活状态则返回 true
     */
    public boolean isActive() {
        return this == ACTIVE;
    }
}