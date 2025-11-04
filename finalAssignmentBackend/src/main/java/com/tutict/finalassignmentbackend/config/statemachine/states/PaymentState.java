package com.tutict.finalassignmentbackend.config.statemachine.states;

import lombok.Getter;

/**
 * 支付状态枚举
 * 对应数据库表 fine_record 的 payment_status 字段
 */
@Getter
public enum PaymentState {
    /**
     * 未支付 - 初始状态
     */
    UNPAID("Unpaid", "未支付"),

    /**
     * 部分支付 - 已支付部分金额
     */
    PARTIAL("Partial", "部分支付"),

    /**
     * 已支付 - 全额支付完成
     */
    PAID("Paid", "已支付"),

    /**
     * 逾期 - 超过缴款期限未支付
     */
    OVERDUE("Overdue", "逾期"),

    /**
     * 减免 - 罚款被减免
     */
    WAIVED("Waived", "减免");

    private final String code;
    private final String description;

    PaymentState(String code, String description) {
        this.code = code;
        this.description = description;
    }

    /**
     * 根据代码获取状态
     *
     * @param code 状态代码
     * @return 状态枚举，如果未找到则返回 null
     */
    public static PaymentState fromCode(String code) {
        if (code == null) {
            return null;
        }
        for (PaymentState state : values()) {
            if (state.code.equalsIgnoreCase(code)) {
                return state;
            }
        }
        return null;
    }
}