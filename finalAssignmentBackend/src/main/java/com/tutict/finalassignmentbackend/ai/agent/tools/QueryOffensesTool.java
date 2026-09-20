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

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

@Component
public class QueryOffensesTool implements AgentTool {

    private final OffenseRecordService offenseRecordService;

    public QueryOffensesTool(OffenseRecordService offenseRecordService) {
        this.offenseRecordService = offenseRecordService;
    }

    @Override
    public String name() {
        return "query_my_offenses";
    }

    @Override
    public String description() {
        return "查询当前驾驶员自己的违法记录。";
    }

    @Override
    public Map<String, Object> parameterSchema() {
        return AgentDrafts.schema();
    }

    @Override
    public Set<AiAgentRole> roles() {
        return Set.of(AiAgentRole.DRIVER);
    }

    @Override
    public boolean mutation() {
        return false;
    }

    @Override
    public AgentToolResult execute(AgentToolContext context, Map<String, Object> arguments) {
        if (context.driverId() == null) {
            return AgentToolResult.error("当前账号尚未绑定驾驶员档案，无法查询违法记录。");
        }
        int page = AgentArgs.page(arguments);
        int size = AgentArgs.size(arguments, 10);
        List<OffenseRecord> records = offenseRecordService.findByDriverId(context.driverId(), page, size);
        return AgentToolResult.result(
                records.isEmpty() ? "没有查询到您的违法记录。" : "共找到 " + records.size() + " 条违法记录。",
                summarize(records),
                AgentDrafts.navigate("查看违法详情", "/userOffenseListPage")
        );
    }

    static List<Map<String, Object>> summarize(List<OffenseRecord> records) {
        List<Map<String, Object>> items = new ArrayList<>();
        for (OffenseRecord record : records) {
            Map<String, Object> item = new LinkedHashMap<>();
            item.put("id", record.getOffenseId());
            item.put("number", record.getOffenseNumber());
            item.put("code", record.getOffenseCode());
            item.put("location", record.getOffenseLocation());
            item.put("status", record.getProcessStatus());
            item.put("plate", record.getLicensePlate());
            item.put("fineAmount", record.getFineAmount());
            items.add(item);
        }
        return items;
    }
}
