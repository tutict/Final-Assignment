package com.tutict.finalassignmentbackend.ai.guardrail;

import java.util.List;

/**
 * 一次注入扫描的结果。
 *
 * @param suspicious  是否命中注入特征
 * @param signals     命中的特征描述（用于审计/日志，不含原文）
 * @param sanitized   已中和后的文本（命中片段被替换为占位标记）
 */
public record InjectionScan(
        boolean suspicious,
        List<String> signals,
        String sanitized
) {
    public InjectionScan {
        signals = signals == null ? List.of() : List.copyOf(signals);
        sanitized = sanitized == null ? "" : sanitized;
    }

    public static InjectionScan clean(String text) {
        return new InjectionScan(false, List.of(), text == null ? "" : text);
    }
}