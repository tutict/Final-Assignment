package com.tutict.finalassignmentbackend.ai.agent.tools;

import com.tutict.finalassignmentbackend.ai.agent.AgentArgs;
import com.tutict.finalassignmentbackend.ai.agent.AgentDrafts;
import com.tutict.finalassignmentbackend.ai.agent.AgentTool;
import com.tutict.finalassignmentbackend.ai.agent.AgentToolContext;
import com.tutict.finalassignmentbackend.ai.agent.AgentToolResult;
import com.tutict.finalassignmentbackend.ai.prompt.AiAgentRole;
import com.tutict.finalassignmentbackend.entity.offense.FineRecord;
import com.tutict.finalassignmentbackend.service.offense.FineRecordService;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Map;
import java.util.Set;

@Component
public class QueryFinesAdminTool implements AgentTool {
    private final FineRecordService fineRecordService;
    public QueryFinesAdminTool(FineRecordService fineRecordService) { this.fineRecordService = fineRecordService; }
    @Override public String name() { return "query_fines"; }
    @Override public String description() { return "管理员查询罚款记录。"; }
    @Override public Map<String, Object> parameterSchema() { return AgentDrafts.schema(); }
    @Override public Set<AiAgentRole> roles() { return Set.of(AiAgentRole.ADMIN, AiAgentRole.SUPER_ADMIN); }
    @Override public boolean mutation() { return false; }
    @Override public AgentToolResult execute(AgentToolContext context, Map<String, Object> arguments) {
        Long driverId = AgentArgs.lng(arguments, "driverId", "id");
        String status = AgentArgs.str(arguments, "query", "paymentStatus");
        int page = AgentArgs.page(arguments);
        int size = AgentArgs.size(arguments, 10);
        List<FineRecord> records;
        if (driverId != null) {
            records = fineRecordService.findByDriverId(driverId, page, size);
        } else if (status != null && !status.isBlank()) {
            records = fineRecordService.searchByPaymentStatus(status, page, size);
        } else {
            records = fineRecordService.searchByPaymentStatus("UNPAID", page, size);
        }
        if (records.size() > size) records = records.subList(0, size);
        return AgentToolResult.result(records.isEmpty() ? "没有查询到罚款记录。" : "共找到 " + records.size() + " 条罚款记录。", QueryFinesTool.summarize(records), AgentDrafts.navigate("打开罚款管理", "/fineList"));
    }
}
