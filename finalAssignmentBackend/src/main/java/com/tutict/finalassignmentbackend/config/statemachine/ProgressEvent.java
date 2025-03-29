package com.tutict.finalassignmentbackend.config.statemachine;

// 事件枚举
public enum ProgressEvent {
    SUBMIT,      // 提交新进度
    START_PROCESSING, // 开始处理
    COMPLETE,    // 完成
    ARCHIVE,     // 归档
    REOPEN       // 重新打开（可选）
}