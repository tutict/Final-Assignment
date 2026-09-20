package com.tutict.finalassignmentbackend.ai.agent.tools;

import com.tutict.finalassignmentbackend.ai.agent.AgentArgs;
import com.tutict.finalassignmentbackend.ai.agent.AgentDrafts;
import com.tutict.finalassignmentbackend.ai.agent.AgentTool;
import com.tutict.finalassignmentbackend.ai.agent.AgentToolContext;
import com.tutict.finalassignmentbackend.ai.agent.AgentToolResult;
import com.tutict.finalassignmentbackend.ai.prompt.AiAgentRole;
import com.tutict.finalassignmentbackend.entity.appeal.AppealRecord;
import com.tutict.finalassignmentbackend.service.appeal.AppealRecordService;
import org.springframework.stereotype.Component;

import java.time.LocalDateTime;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.Set;
import java.util.UUID;

@Component
public class PrepareAppealTool implements AgentTool {
    private final AppealRecordService appealRecordService;
    public PrepareAppealTool(AppealRecordService appealRecordService) { this.appealRecordService = appealRecordService; }
    @Override public String name() { return "prepare_appeal"; }
    @Override public String description() { return "起草申诉。首次只生成待确认草稿，确认后才会提交。"; }
    @Override public Map<String, Object> parameterSchema() {
        return Map.of("type", "object", "properties", Map.of(
                "offenseId", Map.of("type", "integer"),
                "reason", Map.of("type", "string"),
                "appealType", Map.of("type", "string")
        ));
    }
    @Override public Set<AiAgentRole> roles() { return Set.of(AiAgentRole.DRIVER, AiAgentRole.ADMIN, AiAgentRole.SUPER_ADMIN); }
    @Override public boolean mutation() { return true; }
    @Override public String serviceName() { return "AppealRecordService.createAppeal"; }
    @Override public AgentToolResult execute(AgentToolContext context, Map<String, Object> arguments) {
        Long offenseId = AgentArgs.lng(arguments, "offenseId", "id");
        String reason = AgentArgs.str(arguments, "reason", "appealReason", "query");
        if (reason == null || reason.isBlank()) reason = "对处罚结果有异议，申请复核。";
        Long driverId = context.isUser() ? context.driverId() : AgentArgs.lng(arguments, "driverId");
        if (driverId == null) return AgentToolResult.error(context.isUser() ? "请先完善驾驶员档案再提交申诉。" : "请提供驾驶员 ID。");
        Map<String, Object> preview = new LinkedHashMap<>();
        preview.put("offenseId", offenseId);
        preview.put("driverId", driverId);
        preview.put("reason", reason);
        if (!context.confirmed()) {
            return AgentToolResult.draft(AgentDrafts.create(context, this, "即将提交申诉，请确认后办理。", preview, arguments.isEmpty() ? preview : arguments));
        }
        AppealRecord record = new AppealRecord();
        record.setOffenseId(offenseId);
        record.setDriverId(driverId);
        record.setAppealReason(reason);
        record.setAppealType(AgentArgs.str(arguments, "appealType") == null ? "RECONSIDERATION" : AgentArgs.str(arguments, "appealType"));
        record.setAppealTime(LocalDateTime.now());
        record.setCreatedBy(context.username());
        record.setUpdatedBy(context.username());
        AppealRecord saved = appealRecordService.createAppeal(record);
        return AgentToolResult.result("申诉已提交，编号 " + saved.getAppealId() + "。", QueryAppealsTool.summarize(java.util.List.of(saved)), AgentDrafts.navigate("查看申诉", "/userAppeal"));
    }
}
