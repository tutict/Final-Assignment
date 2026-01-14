package com.tutict.finalassignmentcloud.enums;

import lombok.Getter;

/**
 * 角色类型枚举
 * 定义系统中支持的角色类型
 */
@Getter
public enum RoleType {
    /**
     * 系统角色 - 系统内置的基础角色，具有系统级权限
     */
    SYSTEM("System", "系统角色"),

    /**
     * 业务角色 - 面向业务流程的角色，如交通管理员、违章处理员等
     */
    BUSINESS("Business", "业务角色"),

    /**
     * 自定义角色- 由管理员自定义创建的角色
     */
    CUSTOM("Custom", "自定义角色");

    private final String code;
    private final String description;

    RoleType(String code, String description) {
        this.code = code;
        this.description = description;
    }

    /**
     * 根据代码获取角色类型
     *
     * @param code 角色类型代码
     * @return 角色类型枚举，如果未找到则返回null
     */
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

    /**
     * 验证给定的代码是否为有效的角色类型
     *
     * @param code 角色类型代码
     * @return 如果代码有效则返回true，否则返回false
     */
    public static boolean isValid(String code) {
        return fromCode(code) != null;
    }
}

