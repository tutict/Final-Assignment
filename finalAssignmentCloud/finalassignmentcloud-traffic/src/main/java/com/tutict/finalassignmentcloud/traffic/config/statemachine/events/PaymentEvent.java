package com.tutict.finalassignmentcloud.traffic.config.statemachine.events;

/**
 * 支付事件枚举
 * 定义支付状态转换触发的事件
 */
public enum PaymentEvent {
    /**
     * 部分支付 - 从未支付到部分支付
     */
    PARTIAL_PAY,

    /**
     * 完成支付 - 支付完成
     */
    COMPLETE_PAYMENT,

    /**
     * 标记逾期 - 标记为逾期
     */
    MARK_OVERDUE,

    /**
     * 减免罚款 - 减免罚款金额
     */
    WAIVE_FINE,

    /**
     * 继续支付 - 从部分支付继续支付
     */
    CONTINUE_PAYMENT
}

