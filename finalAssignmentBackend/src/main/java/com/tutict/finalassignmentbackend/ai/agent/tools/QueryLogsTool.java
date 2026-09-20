package com.tutict.finalassignmentbackend.ai.agent.tools;

import com.tutict.finalassignmentbackend.ai.agent.AgentArgs;
import com.tutict.finalassignmentbackend.ai.agent.AgentDrafts;
import com.tutict.finalassignmentbackend.ai.agent.AgentTool;
import com.tutict.finalassignmentbackend.ai.agent.AgentToolContext;
import com.tutict.finalassignmentbackend.ai.agent.AgentToolResult;
import com.tutict.finalassignmentbackend.ai.prompt.AiAgentRole;
import com.tutict.finalassignmentbackend.entity.audit.AuditLoginLog;
import com.tutict.finalassignmentbackend.entity.audit.AuditOperationLog;
import com.tutict.finalassignmentbackend.service.audit.AuditLoginLogService;
import com.tutict.finalassignmentbackend.service.audit.AuditOperationLogService;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

@Component
public class QueryLogsTool implements AgentTool {
    private final AuditOperationLogService operationLogService;
    private final AuditLoginLogService loginLogService;

    public QueryLogsTool(AuditOperationLogService operationLogService, AuditLoginLogService loginLogService) {
        this.operationLogService = operationLogService;
        this.loginLogService = loginLogService;
    }

    @Override public String name() { return "query_logs"; }
    @Override public String description() { return "超级管理员检索登录日志和操作日志，只返回低风险摘要。"; }
    @Override public Map<String, Object> parameterSchema() { return AgentDrafts.schema(); }
    @Override public Set<AiAgentRole> roles() { return Set.of(AiAgentRole.SUPER_ADMIN); }
    @Override public boolean mutation() { return false; }

    @Override
    public AgentToolResult execute(AgentToolContext context, Map<String, Object> arguments) {
        int size = AgentArgs.size(arguments, 10);
        String query = AgentArgs.str(arguments, "query", "username");
        List<Map<String, Object>> items = new ArrayList<>();
        List<AuditOperationLog> operations = query == null || query.isBlank()
                ? operationLogService.findRecent(size)
                : operationLogService.searchByUsername(query, 0, size);
        for (AuditOperationLog log : operations) {
            Map<String, Object> item = new LinkedHashMap<>();
            item.put("kind", "operation");
            item.put("id", log.getLogId());
            item.put("type", log.getOperationType());
            item.put("module", log.getOperationModule());
            item.put("username", log.getUsername());
            item.put("result", log.getOperationResult());
            items.add(item);
        }
        List<AuditLoginLog> logins = query == null || query.isBlank()
                ? loginLogService.findRecent(Math.min(5, size))
                : loginLogService.searchByUsername(query, 0, Math.min(5, size));
        for (AuditLoginLog log : logins) {
            Map<String, Object> item = new LinkedHashMap<>();
            item.put("kind", "login");
            item.put("id", log.getLogId());
            item.put("username", log.getUsername());
            item.put("result", log.getLoginResult());
            items.add(item);
        }
        return AgentToolResult.result(
                items.isEmpty() ? "没有查询到日志。" : "共找到 " + items.size() + " 条日志摘要。",
                items,
                AgentDrafts.navigate("打开日志审查", "/admin/logManagement")
        );
    }
}
