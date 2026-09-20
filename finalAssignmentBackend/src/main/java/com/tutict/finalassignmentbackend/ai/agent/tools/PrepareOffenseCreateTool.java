package com.tutict.finalassignmentbackend.ai.agent.tools;

import com.tutict.finalassignmentbackend.ai.agent.AgentArgs;
import com.tutict.finalassignmentbackend.ai.agent.AgentDrafts;
import com.tutict.finalassignmentbackend.ai.agent.AgentTool;
import com.tutict.finalassignmentbackend.ai.agent.AgentToolContext;
import com.tutict.finalassignmentbackend.ai.agent.AgentToolResult;
import com.tutict.finalassignmentbackend.ai.prompt.AiAgentRole;
import com.tutict.finalassignmentbackend.entity.offense.OffenseRecord;
import com.tutict.finalassignmentbackend.service.offense.OffenseRecordService;
import org.springframework.stereotype.Component;

import java.time.LocalDateTime;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.Set;

@Component
public class PrepareOffenseCreateTool implements AgentTool {
    private final OffenseRecordService offenseRecordService;
    public PrepareOffenseCreateTool(OffenseRecordService offenseRecordService) { this.offenseRecordService = offenseRecordService; }
    @Override public String name() { return "prepare_offense_create"; }
    @Override public String description() { return "起草违法录入。确认后才会创建违法记录。"; }
    @Override public Map<String, Object> parameterSchema() { return AgentDrafts.schema("driverId"); }
    @Override public Set<AiAgentRole> roles() { return Set.of(AiAgentRole.ADMIN, AiAgentRole.SUPER_ADMIN); }
    @Override public boolean mutation() { return true; }
    @Override public String serviceName() { return "OffenseRecordService.createOffenseRecord"; }
    @Override public AgentToolResult execute(AgentToolContext context, Map<String, Object> arguments) {
        Long driverId = AgentArgs.lng(arguments, "driverId", "id");
        String location = AgentArgs.str(arguments, "location", "offenseLocation", "query");
        String code = AgentArgs.str(arguments, "offenseCode", "code");
        Map<String, Object> preview = new LinkedHashMap<>();
        preview.put("driverId", driverId);
        preview.put("location", location);
        preview.put("offenseCode", code);
        if (!context.confirmed()) {
            return AgentToolResult.draft(AgentDrafts.create(context, this, "即将录入违法记录，请确认后办理。", preview, arguments));
        }
        OffenseRecord record = new OffenseRecord();
        record.setDriverId(driverId);
        record.setOffenseLocation(location);
        record.setOffenseCode(code);
        record.setOffenseTime(LocalDateTime.now());
        record.setCreatedBy(context.username());
        record.setUpdatedBy(context.username());
        OffenseRecord saved = offenseRecordService.createOffenseRecord(record);
        return AgentToolResult.result("违法记录已录入，ID " + saved.getOffenseId() + "。", QueryOffensesTool.summarize(java.util.List.of(saved)), AgentDrafts.navigate("打开违法管理", "/offenseList"));
    }
}
