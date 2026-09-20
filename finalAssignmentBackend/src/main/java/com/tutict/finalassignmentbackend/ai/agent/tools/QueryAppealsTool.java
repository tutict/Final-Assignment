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

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

@Component
public class QueryAppealsTool implements AgentTool {
    private final AppealRecordService appealRecordService;
    public QueryAppealsTool(AppealRecordService appealRecordService) { this.appealRecordService = appealRecordService; }
    @Override public String name() { return "query_my_appeals"; }
    @Override public String description() { return "查询当前驾驶员自己的申诉记录。"; }
    @Override public Map<String, Object> parameterSchema() { return AgentDrafts.schema(); }
    @Override public Set<AiAgentRole> roles() { return Set.of(AiAgentRole.DRIVER); }
    @Override public boolean mutation() { return false; }
    @Override public AgentToolResult execute(AgentToolContext context, Map<String, Object> arguments) {
        if (context.driverId() == null) return AgentToolResult.error("当前账号尚未绑定驾驶员档案，无法查询申诉。");
        List<AppealRecord> records = appealRecordService.findByDriverId(context.driverId(), AgentArgs.page(arguments), AgentArgs.size(arguments, 10));
        return AgentToolResult.result(records.isEmpty() ? "没有查询到您的申诉记录。" : "共找到 " + records.size() + " 条申诉记录。", summarize(records), AgentDrafts.navigate("查看我的申诉", "/userAppeal"));
    }
    static List<Map<String, Object>> summarize(List<AppealRecord> records) {
        List<Map<String, Object>> items = new ArrayList<>();
        for (AppealRecord record : records) {
            Map<String, Object> item = new LinkedHashMap<>();
            item.put("id", record.getAppealId());
            item.put("number", record.getAppealNumber());
            item.put("reason", record.getAppealReason());
            item.put("status", record.getProcessStatus());
            items.add(item);
        }
        return items;
    }
}
