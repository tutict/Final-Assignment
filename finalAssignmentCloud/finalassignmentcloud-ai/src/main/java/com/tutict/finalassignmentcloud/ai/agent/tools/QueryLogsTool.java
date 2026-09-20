package com.tutict.finalassignmentcloud.ai.agent.tools;

import com.tutict.finalassignmentcloud.ai.agent.AgentArgs;
import com.tutict.finalassignmentcloud.ai.agent.AgentBusinessException;
import com.tutict.finalassignmentcloud.ai.agent.AgentBusinessGateway;
import com.tutict.finalassignmentcloud.ai.agent.AgentDrafts;
import com.tutict.finalassignmentcloud.ai.agent.AgentTool;
import com.tutict.finalassignmentcloud.ai.agent.AgentToolContext;
import com.tutict.finalassignmentcloud.ai.agent.AgentToolResult;
import com.tutict.finalassignmentcloud.ai.prompt.AiAgentRole;
import org.springframework.stereotype.Component;

import java.time.Instant;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;

@Component
public class QueryLogsTool implements AgentTool {
    private final AgentBusinessGateway gateway;
    public QueryLogsTool(AgentBusinessGateway gateway) { this.gateway = gateway; }
    @Override public String name() { return "query_logs"; }
    @Override public String description() { return "超级管理员检索登录日志和操作日志，只返回低风险摘要。"; }
    @Override public Map<String, Object> parameterSchema() { return AgentDrafts.schema(); }
    @Override public Set<AiAgentRole> roles() { return Set.of(AiAgentRole.SUPER_ADMIN); }
    @Override public boolean mutation() { return false; }
    @Override public AgentToolResult execute(AgentToolContext context, Map<String, Object> arguments) {
        try {
            String query = AgentArgs.str(arguments, "query", "username");
            List<Map<String, Object>> items = new ArrayList<>();
            for (Map<String, Object> log : gateway.operations(query)) {
                Map<String, Object> item = new LinkedHashMap<>();
                item.put("kind", "operation");
                item.put("id", log.getOrDefault("logId", log.get("id")));
                item.put("type", log.get("operationType"));
                item.put("module", log.get("operationModule"));
                item.put("username", log.get("username"));
                item.put("result", log.get("operationResult"));
                items.add(item);
            }
            for (Map<String, Object> log : gateway.logins(query)) {
                Map<String, Object> item = new LinkedHashMap<>();
                item.put("kind", "login");
                item.put("id", log.getOrDefault("logId", log.get("id")));
                item.put("username", log.get("username"));
                item.put("result", log.get("loginResult"));
                items.add(item);
            }
            return AgentToolResult.result(items.isEmpty() ? "没有查询到日志。" : "共找到 " + items.size() + " 条日志摘要。",
                    items, AgentDrafts.navigate("打开日志审查", "/admin/logManagement"));
        } catch (AgentBusinessException ex) {
            return AgentToolResult.error(ex.getMessage());
        }
    }
}
