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

import java.util.List;
import java.util.Map;
import java.util.Set;

@Component
public class QueryOffensesAdminTool implements AgentTool {

    private final OffenseRecordService offenseRecordService;

    public QueryOffensesAdminTool(OffenseRecordService offenseRecordService) {
        this.offenseRecordService = offenseRecordService;
    }

    @Override
    public String name() {
        return "query_offenses";
    }

    @Override
    public String description() {
        return "管理员查询违法记录，可按驾驶员或编号过滤。";
    }

    @Override
    public Map<String, Object> parameterSchema() {
        return AgentDrafts.schema();
    }

    @Override
    public Set<AiAgentRole> roles() {
        return Set.of(AiAgentRole.ADMIN, AiAgentRole.SUPER_ADMIN);
    }

    @Override
    public boolean mutation() {
        return false;
    }

    @Override
    public AgentToolResult execute(AgentToolContext context, Map<String, Object> arguments) {
        int page = AgentArgs.page(arguments);
        int size = AgentArgs.size(arguments, 10);
        Long driverId = AgentArgs.lng(arguments, "driverId", "id");
        String query = AgentArgs.str(arguments, "query", "offenseNumber");
        List<OffenseRecord> records;
        if (driverId != null) {
            records = offenseRecordService.findByDriverId(driverId, page, size);
        } else if (query != null && !query.isBlank()) {
            records = offenseRecordService.searchByOffenseNumber(query, page, size);
        } else {
            records = offenseRecordService.findPage(page, size).getRecords();
        }
        return AgentToolResult.result(
                records.isEmpty() ? "没有查询到违法记录。" : "共找到 " + records.size() + " 条违法记录。",
                QueryOffensesTool.summarize(records),
                AgentDrafts.navigate("打开违法管理", "/offenseList")
        );
    }
}
