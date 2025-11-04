package com.tutict.finalassignmentbackend.config.statemachine.states;

import lombok.Getter;

/**
 * 申诉受理状态枚举
 * 对应数据库表 appeal_record 的 acceptance_status 字段
 */
@Getter
public enum AppealAcceptanceState {
    /**
     * 待受理 - 初始状态
     */
    PENDING("Pending", "待受理"),

    /**
     * 已受理 - 受理通过
     */
    ACCEPTED("Accepted", "已受理"),

    /**
     * 不予受理 - 受理驳回
     */
    REJECTED("Rejected", "不予受理"),

    /**
     * 需补充材料 - 材料不足，需要补充
     */
    NEED_SUPPLEMENT("Need_Supplement", "需补充材料");

    private final String code;
    private final String description;

    AppealAcceptanceState(String code, String description) {
        this.code = code;
        this.description = description;
    }

    /**
     * 根据代码获取状态
     *
     * @param code 状态代码
     * @return 状态枚举，如果未找到则返回 null
     */
    public static AppealAcceptanceState fromCode(String code) {
        if (code == null) {
            return null;
        }
        for (AppealAcceptanceState state : values()) {
            if (state.code.equalsIgnoreCase(code)) {
                return state;
            }
        }
        return null;
    }
}