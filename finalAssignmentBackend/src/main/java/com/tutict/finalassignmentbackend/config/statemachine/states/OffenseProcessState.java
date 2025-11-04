package com.tutict.finalassignmentbackend.config.statemachine.states;

import lombok.Getter;

/**
 * 违法记录处理状态枚举
 * 对应数据库表 offense_record 的 process_status 字段
 */
@Getter
public enum OffenseProcessState {
    /**
     * 未处理 - 初始状态
     */
    UNPROCESSED("Unprocessed", "未处理"),

    /**
     * 处理中 - 正在处理中
     */
    PROCESSING("Processing", "处理中"),

    /**
     * 已处理 - 处理完成
     */
    PROCESSED("Processed", "已处理"),

    /**
     * 申诉中 - 正在申诉
     */
    APPEALING("Appealing", "申诉中"),

    /**
     * 申诉通过 - 申诉成功
     */
    APPEAL_APPROVED("Appeal_Approved", "申诉通过"),

    /**
     * 申诉驳回 - 申诉失败
     */
    APPEAL_REJECTED("Appeal_Rejected", "申诉驳回"),

    /**
     * 已取消 - 记录被取消
     */
    CANCELLED("Cancelled", "已取消");

    private final String code;
    private final String description;

    OffenseProcessState(String code, String description) {
        this.code = code;
        this.description = description;
    }

    /**
     * 根据代码获取状态
     *
     * @param code 状态代码
     * @return 状态枚举，如果未找到则返回 null
     */
    public static OffenseProcessState fromCode(String code) {
        if (code == null) {
            return null;
        }
        for (OffenseProcessState state : values()) {
            if (state.code.equalsIgnoreCase(code)) {
                return state;
            }
        }
        return null;
    }
}