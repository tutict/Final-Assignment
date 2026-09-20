package com.tutict.finalassignmentcloud.ai.agent.tools;

import com.tutict.finalassignmentcloud.ai.agent.AgentArgs;
import com.tutict.finalassignmentcloud.ai.agent.AgentBusinessException;
import com.tutict.finalassignmentcloud.ai.agent.AgentBusinessGateway;
import com.tutict.finalassignmentcloud.ai.agent.AgentDraft;
import com.tutict.finalassignmentcloud.ai.agent.AgentDraftStore;
import com.tutict.finalassignmentcloud.ai.agent.AgentDrafts;
import com.tutict.finalassignmentcloud.ai.agent.AgentTool;
import com.tutict.finalassignmentcloud.ai.agent.AgentToolContext;
import com.tutict.finalassignmentcloud.ai.agent.AgentToolRegistry;
import com.tutict.finalassignmentcloud.ai.agent.AgentToolResult;
import com.tutict.finalassignmentcloud.ai.client.rag.RagRetrievalResult;
import com.tutict.finalassignmentcloud.ai.prompt.AiAgentRole;
import org.springframework.context.annotation.Lazy;
import org.springframework.stereotype.Component;

import java.time.Instant;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;

@Component
public class SearchKnowledgeTool implements AgentTool {
    private final AgentBusinessGateway gateway;
    public SearchKnowledgeTool(AgentBusinessGateway gateway) { this.gateway = gateway; }
    @Override public String name() { return "search_knowledge"; }
    @Override public String description() { return "在 RAG 知识库中检索法规、流程和已录入资料。"; }
    @Override public Map<String, Object> parameterSchema() {
        return Map.of("type", "object", "properties", Map.of("query", Map.of("type", "string")), "required", List.of("query"));
    }
    @Override public Set<AiAgentRole> roles() { return Set.of(AiAgentRole.DRIVER, AiAgentRole.ADMIN, AiAgentRole.SUPER_ADMIN); }
    @Override public boolean mutation() { return false; }
    @Override public AgentToolResult execute(AgentToolContext context, Map<String, Object> arguments) {
        String query = AgentArgs.str(arguments, "query");
        if (query == null || query.isBlank()) return AgentToolResult.error("请提供检索关键字。");
        try {
            String roleCode = context.role() == AiAgentRole.DRIVER ? "USER" : context.role().name();
            List<RagRetrievalResult> results = gateway.searchKnowledge(query, context.userKey(), List.of(roleCode));
            List<Map<String, Object>> items = new ArrayList<>();
            for (RagRetrievalResult result : results) {
                Map<String, Object> item = new LinkedHashMap<>();
                item.put("title", result.title());
                item.put("content", result.content());
                item.put("route", result.route());
                items.add(item);
            }
            return AgentToolResult.result(items.isEmpty() ? "知识库没有匹配资料。" : "检索到 " + items.size() + " 条资料。", items, null);
        } catch (AgentBusinessException ex) {
            return AgentToolResult.error(ex.getMessage());
        }
    }
}
