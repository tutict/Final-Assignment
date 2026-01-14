package com.tutict.finalassignmentcloud.traffic.config.statemachine.events;

/**
 * 扣分记录事件枚举
 * 定义扣分状态转换触发的事件
 */
public enum DeductionEvent {
    /**
     * 取消扣分 - 从生效中到已取消
     */
    CANCEL,

    /**
     * 恢复扣分 - 从生效中到已恢复（如申诉成功后恢复积分）
     */
    RESTORE,

    /**
     * 重新生效 - 从已取消恢复到生效中
     */
    REACTIVATE
}

