package com.tutict.finalassignmentbackend.ai.agent.tools;

import com.tutict.finalassignmentbackend.ai.agent.AgentArgs;
import com.tutict.finalassignmentbackend.ai.agent.AgentDrafts;
import com.tutict.finalassignmentbackend.ai.agent.AgentTool;
import com.tutict.finalassignmentbackend.ai.agent.AgentToolContext;
import com.tutict.finalassignmentbackend.ai.agent.AgentToolResult;
import com.tutict.finalassignmentbackend.ai.prompt.AiAgentRole;
import com.tutict.finalassignmentbackend.rag.dto.RagSourceDocument;
import com.tutict.finalassignmentbackend.rag.service.RagIndexingService;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.stereotype.Component;

import java.time.Instant;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;

@Component
public class IngestRagDocumentTool implements AgentTool {
    private final ObjectProvider<RagIndexingService> indexingService;

    public IngestRagDocumentTool(ObjectProvider<RagIndexingService> indexingService) {
        this.indexingService = indexingService;
    }

    @Override public String name() { return "ingest_rag_document"; }
    @Override public String description() { return "起草 RAG 资料录入。确认后才会写入知识库并建立索引。"; }
    @Override public Map<String, Object> parameterSchema() {
        return Map.of(
                "type", "object",
                "properties", Map.of(
                        "title", Map.of("type", "string"),
                        "content", Map.of("type", "string")
                ),
                "required", List.of("title", "content")
        );
    }
    @Override public Set<AiAgentRole> roles() { return Set.of(AiAgentRole.ADMIN, AiAgentRole.SUPER_ADMIN); }
    @Override public boolean mutation() { return true; }
    @Override public String risk() { return "high"; }
    @Override public String serviceName() { return "RagIndexingService.index"; }

    @Override
    public AgentToolResult execute(AgentToolContext context, Map<String, Object> arguments) {
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
        RagIndexingService service = indexingService.getIfAvailable();
        if (service == null) {
            return AgentToolResult.error("RAG 索引服务暂未启用，资料未写入。");
        }
        RagSourceDocument source = new RagSourceDocument(
                "MANUAL",
                "manual_rag_document",
                "manual-" + UUID.randomUUID(),
                "v" + Instant.now().toEpochMilli(),
                title,
                content,
                "PUBLIC",
                "",
                "{}",
                "content"
        );
        RagIndexingService.RagIndexingResult result = service.index(source);
        return AgentToolResult.result(
                "资料已录入，文档 ID " + result.document().getId() + "，分块 " + result.chunks().size() + "。",
                List.of(Map.of(
                        "documentId", result.document().getId(),
                        "title", title,
                        "chunkCount", result.chunks().size()
                )),
                AgentDrafts.navigate("打开 RAG 资料管理", "/ragManagement")
        );
    }
}
