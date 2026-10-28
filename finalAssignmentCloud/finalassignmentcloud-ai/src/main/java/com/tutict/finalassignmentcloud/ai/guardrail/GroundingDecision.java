package com.tutict.finalassignmentcloud.ai.guardrail;

/**
 * 引用强制（grounding）判定结果。
 *
 * @param grounded  回答是否有可核验的来源支撑
 * @param answer    最终对外的回答文本：grounded 时为原回答，否则为安全兜底回答
 * @param reason    判定原因（grounded / missing_citation / no_sources / disabled）
 */
public record GroundingDecision(
        boolean grounded,
        String answer,
        String reason
) {
    public static GroundingDecision allowed(String answer) {
        return new GroundingDecision(true, answer, "grounded");
    }

    public static GroundingDecision refused(String answer, String reason) {
        return new GroundingDecision(false, answer, reason);
    }
}
