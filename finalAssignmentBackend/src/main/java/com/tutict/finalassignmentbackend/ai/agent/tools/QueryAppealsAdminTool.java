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

import java.util.List;
import java.util.Map;
import java.util.Set;

@Component
public class QueryAppealsAdminTool implements AgentTool {
    private final AppealRecordService appealRecordService;
    public QueryAppealsAdminTool(AppealRecordService appealRecordService) { this.appealRecordService = appealRecordService; }
    @Override public String name() { return "query_appeals"; }
    @Override public String description() { return "管理员查询申诉记录。"; }
    @Override public Map<String, Object> parameterSchema() { return AgentDrafts.schema(); }
    @Override public Set<AiAgentRole> roles() { return Set.of(AiAgentRole.ADMIN, AiAgentRole.SUPER_ADMIN); }
    @Override public boolean mutation() { return false; }
    @Override public AgentToolResult execute(AgentToolContext context, Map<String, Object> arguments) {
        Long driverId = AgentArgs.lng(arguments, "driverId", "id");
        String query = AgentArgs.str(arguments, "query");
        int page = AgentArgs.page(arguments);
        int size = AgentArgs.size(arguments, 10);
        List<AppealRecord> records;
        if (driverId != null) {
            records = appealRecordService.findByDriverId(driverId, page, size);
        } else if (query != null && !query.isBlank()) {
            records = appealRecordService.searchByAppealNumberFuzzy(query, page, size);
        } else {
            records = appealRecordService.searchByProcessStatus("Unprocessed", page, size);
        }
        if (records == null) records = List.of();
        return AgentToolResult.result(records.isEmpty() ? "没有查询到申诉记录。" : "共找到 " + records.size() + " 条申诉记录。", QueryAppealsTool.summarize(records), AgentDrafts.navigate("打开申诉审批", "/appealManagement"));
    }
}
