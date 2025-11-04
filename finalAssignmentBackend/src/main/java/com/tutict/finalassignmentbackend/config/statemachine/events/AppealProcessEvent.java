package com.tutict.finalassignmentbackend.config.statemachine.events;

/**
 * 申诉处理事件枚举
 * 定义申诉处理状态转换触发的事件
 */
public enum AppealProcessEvent {
    /**
     * 开始审核 - 从未处理到审核中
     */
    START_REVIEW,

    /**
     * 批准申诉 - 从审核中到已批准
     */
    APPROVE,

    /**
     * 驳回申诉 - 从审核中到已驳回
     */
    REJECT,

    /**
     * 撤回申诉 - 撤回申诉
     */
    WITHDRAW,

    /**
     * 重新审核 - 从已驳回到审核中
     */
    REOPEN_REVIEW
}