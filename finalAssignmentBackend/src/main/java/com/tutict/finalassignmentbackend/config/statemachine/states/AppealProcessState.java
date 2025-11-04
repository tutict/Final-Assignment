package com.tutict.finalassignmentbackend.config.statemachine.states;

import lombok.Getter;

/**
 * 申诉处理状态枚举
 * 对应数据库表 appeal_record 的 process_status 字段
 */
@Getter
public enum AppealProcessState {
    /**
     * 未处理 - 初始状态
     */
    UNPROCESSED("Unprocessed", "未处理"),

    /**
     * 审核中 - 正在审核
     */
    UNDER_REVIEW("Under_Review", "审核中"),

    /**
     * 已批准 - 申诉通过
     */
    APPROVED("Approved", "已批准"),

    /**
     * 已驳回 - 申诉驳回
     */
    REJECTED("Rejected", "已驳回"),

    /**
     * 已撤回 - 申诉人主动撤回
     */
    WITHDRAWN("Withdrawn", "已撤回");

    private final String code;
    private final String description;

    AppealProcessState(String code, String description) {
        this.code = code;
        this.description = description;
    }

    /**
     * 根据代码获取状态
     *
     * @param code 状态代码
     * @return 状态枚举，如果未找到则返回 null
     */
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