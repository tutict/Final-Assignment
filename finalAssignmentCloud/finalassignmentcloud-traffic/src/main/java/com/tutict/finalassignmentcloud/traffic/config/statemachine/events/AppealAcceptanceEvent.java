package com.tutict.finalassignmentcloud.traffic.config.statemachine.events;

/**
 * 申诉受理事件枚举
 * 定义申诉受理状态转换触发的事件
 */
public enum AppealAcceptanceEvent {
    /**
     * 受理申诉 - 从待受理到已受理
     */
    ACCEPT,

    /**
     * 拒绝受理 - 从待受理到不予受理
     */
    REJECT,

    /**
     * 要求补充材料 - 从待受理到需补充材料
     */
    REQUEST_SUPPLEMENT,

    /**
     * 补充材料完成 - 从需补充材料到待受理
     */
    SUPPLEMENT_COMPLETE,

    /**
     * 重新提交 - 从不予受理到待受理
     */
    RESUBMIT
}
