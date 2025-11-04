package com.tutict.finalassignmentbackend.config.statemachine.states;

import lombok.Getter;

/**
 * 扣分记录状态枚举
 * 对应数据库表 deduction_record 的 status 字段
 */
@Getter
public enum DeductionState {
    /**
     * 生效中 - 扣分有效
     */
    EFFECTIVE("Effective", "生效中"),

    /**
     * 已取消 - 扣分被取消
     */
    CANCELLED("Cancelled", "已取消"),

    /**
     * 已恢复 - 扣分被恢复（如申诉成功）
     */
    RESTORED("Restored", "已恢复");

    private final String code;
    private final String description;

    DeductionState(String code, String description) {
        this.code = code;
        this.description = description;
    }

    /**
     * 根据代码获取状态
     *
     * @param code 状态代码
     * @return 状态枚举，如果未找到则返回 null
     */
    public static DeductionState fromCode(String code) {
        if (code == null) {
            return null;
        }
        for (DeductionState state : values()) {
            if (state.code.equalsIgnoreCase(code)) {
                return state;
            }
        }
        return null;
    }
}