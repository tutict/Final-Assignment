package com.tutict.finalassignmentbackend.ai.agent.tools;

import com.tutict.finalassignmentbackend.ai.agent.AgentArgs;
import com.tutict.finalassignmentbackend.ai.agent.AgentDrafts;
import com.tutict.finalassignmentbackend.ai.agent.AgentTool;
import com.tutict.finalassignmentbackend.ai.agent.AgentToolContext;
import com.tutict.finalassignmentbackend.ai.agent.AgentToolResult;
import com.tutict.finalassignmentbackend.ai.prompt.AiAgentRole;
import com.tutict.finalassignmentbackend.entity.offense.DeductionRecord;
import com.tutict.finalassignmentbackend.service.offense.DeductionRecordService;
import org.springframework.stereotype.Component;

import java.time.LocalDateTime;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.Set;

@Component
public class PrepareDeductionCreateTool implements AgentTool {
    private final DeductionRecordService deductionRecordService;
    public PrepareDeductionCreateTool(DeductionRecordService deductionRecordService) { this.deductionRecordService = deductionRecordService; }
    @Override public String name() { return "prepare_deduction_create"; }
    @Override public String description() { return "起草扣分录入。确认后才会创建扣分记录。"; }
    @Override public Map<String, Object> parameterSchema() { return AgentDrafts.schema("driverId"); }
    @Override public Set<AiAgentRole> roles() { return Set.of(AiAgentRole.ADMIN, AiAgentRole.SUPER_ADMIN); }
    @Override public boolean mutation() { return true; }
    @Override public String serviceName() { return "DeductionRecordService.createDeductionRecord"; }
    @Override public AgentToolResult execute(AgentToolContext context, Map<String, Object> arguments) {
        Long driverId = AgentArgs.lng(arguments, "driverId", "id");
        Integer points = AgentArgs.integer(arguments, "points", "deductedPoints");
        Map<String, Object> preview = new LinkedHashMap<>();
        preview.put("driverId", driverId);
        preview.put("points", points);
        if (!context.confirmed()) {
            return AgentToolResult.draft(AgentDrafts.create(context, this, "即将录入扣分，请确认后办理。", preview, arguments));
        }
        DeductionRecord record = new DeductionRecord();
        record.setDriverId(driverId);
        record.setDeductedPoints(points);
        record.setDeductionTime(LocalDateTime.now());
        record.setCreatedBy(context.username());
        DeductionRecord saved = deductionRecordService.createDeductionRecord(record);
        return AgentToolResult.result("扣分已录入，ID " + saved.getDeductionId() + "。", java.util.List.of(Map.of("id", saved.getDeductionId(), "points", saved.getDeductedPoints())), AgentDrafts.navigate("打开扣分管理", "/deductionManagement"));
    }
}
