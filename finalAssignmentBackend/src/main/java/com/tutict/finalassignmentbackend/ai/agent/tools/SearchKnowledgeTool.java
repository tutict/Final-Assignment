package com.tutict.finalassignmentbackend.ai.agent.tools;

import com.tutict.finalassignmentbackend.ai.agent.AgentArgs;
import com.tutict.finalassignmentbackend.ai.agent.AgentDrafts;
import com.tutict.finalassignmentbackend.ai.agent.AgentTool;
import com.tutict.finalassignmentbackend.ai.agent.AgentToolContext;
import com.tutict.finalassignmentbackend.ai.agent.AgentToolResult;
import com.tutict.finalassignmentbackend.ai.prompt.AiAgentRole;
import com.tutict.finalassignmentbackend.ai.rag.dto.RetrievalResult;
import com.tutict.finalassignmentbackend.ai.rag.query.RagQueryService;
import com.tutict.finalassignmentbackend.ai.rag.query.ServerSideRagQueryRequest;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

@Component
public class SearchKnowledgeTool implements AgentTool {
    private final ObjectProvider<RagQueryService> ragQueryService;
    public SearchKnowledgeTool(ObjectProvider<RagQueryService> ragQueryService) { this.ragQueryService = ragQueryService; }
    @Override public String name() { return "search_knowledge"; }
    @Override public String description() { return "在 RAG 知识库中检索法规、流程和已录入资料。"; }
    @Override public Map<String, Object> parameterSchema() {
        return Map.of("type", "object", "properties", Map.of("query", Map.of("type", "string")), "required", List.of("query"));
    }
    @Override public Set<AiAgentRole> roles() { return Set.of(AiAgentRole.DRIVER, AiAgentRole.ADMIN, AiAgentRole.SUPER_ADMIN); }
    @Override public boolean mutation() { return false; }
    @Override public AgentToolResult execute(AgentToolContext context, Map<String, Object> arguments) {
        RagQueryService service = ragQueryService.getIfAvailable();
        if (service == null) return AgentToolResult.error("知识库检索暂未启用。");
        String query = AgentArgs.str(arguments, "query");
        if (query == null || query.isBlank()) return AgentToolResult.error("请提供检索关键字。");
        String roleCode = context.role() == AiAgentRole.DRIVER ? "USER" : context.role().name();
        List<RetrievalResult> results = service.query(new ServerSideRagQueryRequest(
                query,
                5,
                context.username() == null ? context.userKey() : context.username(),
                List.of(roleCode),
                null
        ));
        List<Map<String, Object>> items = new ArrayList<>();
        for (RetrievalResult result : results) {
            Map<String, Object> item = new LinkedHashMap<>();
            item.put("title", result.title());
            item.put("content", result.content());
            item.put("route", result.route());
            items.add(item);
        }
        return AgentToolResult.result(items.isEmpty() ? "知识库没有匹配资料。" : "检索到 " + items.size() + " 条资料。", items, null);
    }
}
