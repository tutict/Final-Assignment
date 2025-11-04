package com.tutict.finalassignmentbackend.config.statemachine.events;

/**
 * 违法记录处理事件枚举
 * 定义违法记录状态转换触发的事件
 */
public enum OffenseProcessEvent {
    /**
     * 开始处理 - 从未处理到处理中
     */
    START_PROCESSING,

    /**
     * 完成处理 - 从处理中到已处理
     */
    COMPLETE_PROCESSING,

    /**
     * 提交申诉 - 从已处理到申诉中
     */
    SUBMIT_APPEAL,

    /**
     * 申诉通过 - 从申诉中到申诉通过
     */
    APPROVE_APPEAL,

    /**
     * 申诉驳回 - 从申诉中到申诉驳回
     */
    REJECT_APPEAL,

    /**
     * 取消记录 - 取消违法记录
     */
    CANCEL,

    /**
     * 撤回申诉 - 从申诉中返回已处理
     */
    WITHDRAW_APPEAL
}