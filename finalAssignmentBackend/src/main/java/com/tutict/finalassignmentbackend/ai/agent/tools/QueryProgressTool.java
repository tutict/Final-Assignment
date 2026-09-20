package com.tutict.finalassignmentbackend.ai.agent.tools;

import com.tutict.finalassignmentbackend.ai.agent.AgentArgs;
import com.tutict.finalassignmentbackend.ai.agent.AgentDrafts;
import com.tutict.finalassignmentbackend.ai.agent.AgentTool;
import com.tutict.finalassignmentbackend.ai.agent.AgentToolContext;
import com.tutict.finalassignmentbackend.ai.agent.AgentToolResult;
import com.tutict.finalassignmentbackend.ai.prompt.AiAgentRole;
import com.tutict.finalassignmentbackend.entity.system.SysRequestHistory;
import com.tutict.finalassignmentbackend.service.system.SysRequestHistoryService;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

@Component
public class QueryProgressTool implements AgentTool {
    private final SysRequestHistoryService historyService;
    public QueryProgressTool(SysRequestHistoryService historyService) { this.historyService = historyService; }
    @Override public String name() { return "query_progress"; }
    @Override public String description() { return "查询业务办理进度。驾驶员查看自己的请求，管理员可按状态过滤。"; }
    @Override public Map<String, Object> parameterSchema() { return AgentDrafts.schema(); }
    @Override public Set<AiAgentRole> roles() { return Set.of(AiAgentRole.DRIVER, AiAgentRole.ADMIN, AiAgentRole.SUPER_ADMIN); }
    @Override public boolean mutation() { return false; }
    @Override public AgentToolResult execute(AgentToolContext context, Map<String, Object> arguments) {
        int page = AgentArgs.page(arguments);
        int size = AgentArgs.size(arguments, 10);
        List<SysRequestHistory> records;
        if (context.isUser()) {
            if (context.authUserId() != null) records = historyService.findByUserId(context.authUserId(), page, size);
            else if (context.username() != null) records = historyService.findByUsername(context.username(), page, size);
            else records = List.of();
        } else {
            String status = AgentArgs.str(arguments, "query", "status");
            records = status == null ? historyService.findRecent(size) : historyService.findByBusinessStatus(status, page, size);
        }
        List<Map<String, Object>> items = new ArrayList<>();
        for (SysRequestHistory record : records) {
            Map<String, Object> item = new LinkedHashMap<>();
            item.put("id", record.getId());
            item.put("type", record.getBusinessType());
            item.put("status", record.getBusinessStatus());
            item.put("url", record.getRequestUrl());
            items.add(item);
        }
        String target = context.isUser() ? "/onlineProcessingProgress" : "/progressManagement";
        return AgentToolResult.result(records.isEmpty() ? "没有查询到办理进度。" : "共找到 " + records.size() + " 条进度记录。", items, AgentDrafts.navigate("查看进度", target));
    }
}
