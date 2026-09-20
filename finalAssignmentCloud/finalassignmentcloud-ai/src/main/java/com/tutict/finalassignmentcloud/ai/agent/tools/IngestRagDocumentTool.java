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
public class IngestRagDocumentTool implements AgentTool {
    private final AgentBusinessGateway gateway;
    public IngestRagDocumentTool(AgentBusinessGateway gateway) { this.gateway = gateway; }
    @Override public String name() { return "ingest_rag_document"; }
    @Override public String description() { return "起草 RAG 资料录入。确认后才会写入知识库并建立索引。"; }
    @Override public Map<String, Object> parameterSchema() {
        return Map.of("type", "object", "properties", Map.of("title", Map.of("type", "string"), "content", Map.of("type", "string")),
                "required", List.of("title", "content"));
    }
    @Override public Set<AiAgentRole> roles() { return Set.of(AiAgentRole.ADMIN, AiAgentRole.SUPER_ADMIN); }
    @Override public boolean mutation() { return true; }
    @Override public String risk() { return "high"; }
    @Override public String serviceName() { return "RagIndexingService.index"; }
    @Override public AgentToolResult execute(AgentToolContext context, Map<String, Object> arguments) {
        String title = AgentArgs.str(arguments, "title", "query");
        String content = AgentArgs.str(arguments, "content");
        if (title == null || title.isBlank() || content == null || content.isBlank()) {
            return AgentToolResult.error("请提供资料标题和正文。");
        }
        Map<String, Object> preview = new LinkedHashMap<>();
        preview.put("title", title);
        preview.put("contentPreview", content.length() > 120 ? content.substring(0, 120) + "..." : content);
        if (!context.confirmed()) {
            return AgentToolResult.draft(AgentDrafts.create(context, this, "即将录入 RAG 资料《" + title + "》，请确认后办理。", preview, arguments));
        }
        try {
            Map<String, Object> body = new LinkedHashMap<>();
            body.put("title", title);
            body.put("content", content);
            body.put("aclScope", "PUBLIC");
            Map<String, Object> saved = gateway.ingestRag(body);
            return AgentToolResult.result("资料已录入。", List.of(saved), AgentDrafts.navigate("打开 RAG 资料管理", "/ragManagement"));
        } catch (AgentBusinessException ex) {
            return AgentToolResult.error(ex.getMessage());
        }
    }
}
