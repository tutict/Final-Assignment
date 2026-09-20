package com.tutict.finalassignmentbackend.ai.agent.tools;

import com.tutict.finalassignmentbackend.ai.agent.AgentArgs;
import com.tutict.finalassignmentbackend.ai.agent.AgentDrafts;
import com.tutict.finalassignmentbackend.ai.agent.AgentTool;
import com.tutict.finalassignmentbackend.ai.agent.AgentToolContext;
import com.tutict.finalassignmentbackend.ai.agent.AgentToolResult;
import com.tutict.finalassignmentbackend.ai.prompt.AiAgentRole;
import com.tutict.finalassignmentbackend.config.statemachine.states.AppealProcessState;
import com.tutict.finalassignmentbackend.entity.appeal.AppealReview;
import com.tutict.finalassignmentbackend.service.appeal.AppealRecordService;
import com.tutict.finalassignmentbackend.service.appeal.AppealReviewService;
import org.springframework.stereotype.Component;

import java.time.LocalDateTime;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.Set;

@Component
public class PrepareAppealReviewTool implements AgentTool {
    private final AppealReviewService appealReviewService;
    private final AppealRecordService appealRecordService;
    public PrepareAppealReviewTool(AppealReviewService appealReviewService, AppealRecordService appealRecordService) {
        this.appealReviewService = appealReviewService;
        this.appealRecordService = appealRecordService;
    }
    @Override public String name() { return "prepare_appeal_review"; }
    @Override public String description() { return "起草申诉审批。确认后才会写入审批结果。"; }
    @Override public Map<String, Object> parameterSchema() {
        return Map.of("type", "object", "properties", Map.of(
                "appealId", Map.of("type", "integer"),
                "result", Map.of("type", "string", "description", "APPROVED 或 REJECTED"),
                "opinion", Map.of("type", "string")
        ), "required", java.util.List.of("appealId", "result"));
    }
    @Override public Set<AiAgentRole> roles() { return Set.of(AiAgentRole.ADMIN, AiAgentRole.SUPER_ADMIN); }
    @Override public boolean mutation() { return true; }
    @Override public String risk() { return "high"; }
    @Override public String serviceName() { return "AppealReviewService.createReview"; }
    @Override public AgentToolResult execute(AgentToolContext context, Map<String, Object> arguments) {
        Long appealId = AgentArgs.lng(arguments, "appealId", "id");
        String result = AgentArgs.str(arguments, "result", "reviewResult");
        if (appealId == null || result == null) return AgentToolResult.error("请提供申诉 ID 和审批结果。");
        Map<String, Object> preview = new LinkedHashMap<>();
        preview.put("appealId", appealId);
        preview.put("result", result);
        preview.put("opinion", AgentArgs.str(arguments, "opinion", "reviewOpinion"));
        if (!context.confirmed()) {
            return AgentToolResult.draft(AgentDrafts.create(context, this, "即将审批申诉 " + appealId + " 为 " + result + "，请确认后办理。", preview, arguments));
        }
        AppealReview review = new AppealReview();
        review.setAppealId(appealId);
        review.setReviewResult(result);
        review.setReviewOpinion(AgentArgs.str(arguments, "opinion", "reviewOpinion"));
        review.setReviewer(context.username());
        review.setReviewTime(LocalDateTime.now());
        AppealReview saved = appealReviewService.createReview(review);
        try {
            if ("APPROVED".equalsIgnoreCase(result) || "通过".equals(result)) {
                appealRecordService.updateProcessStatus(appealId, AppealProcessState.APPROVED);
            } else if ("REJECTED".equalsIgnoreCase(result) || "驳回".equals(result)) {
                appealRecordService.updateProcessStatus(appealId, AppealProcessState.REJECTED);
            }
        } catch (RuntimeException ignored) {
            // keep review even if state transition is not applicable
        }
        return AgentToolResult.result("申诉审批已提交，记录 " + saved.getReviewId() + "。", java.util.List.of(Map.of("reviewId", saved.getReviewId(), "result", result)), AgentDrafts.navigate("打开申诉审批", "/appealManagement"));
    }
}
