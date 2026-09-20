package com.tutict.finalassignmentbackend.ai.agent.tools;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.tutict.finalassignmentbackend.ai.agent.AgentDrafts;
import com.tutict.finalassignmentbackend.ai.agent.AgentTool;
import com.tutict.finalassignmentbackend.ai.agent.AgentToolContext;
import com.tutict.finalassignmentbackend.ai.agent.AgentToolResult;
import com.tutict.finalassignmentbackend.ai.prompt.AiAgentRole;
import com.tutict.finalassignmentbackend.rag.entity.RagDocument;
import com.tutict.finalassignmentbackend.rag.entity.RagEmbeddingTask;
import com.tutict.finalassignmentbackend.rag.mapper.RagChunkMapper;
import com.tutict.finalassignmentbackend.rag.mapper.RagDocumentMapper;
import com.tutict.finalassignmentbackend.rag.mapper.RagEmbeddingTaskMapper;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.stereotype.Component;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

@Component
public class QueryRagStatusTool implements AgentTool {
    private final ObjectProvider<RagDocumentMapper> documentMapper;
    private final ObjectProvider<RagChunkMapper> chunkMapper;
    private final ObjectProvider<RagEmbeddingTaskMapper> taskMapper;

    public QueryRagStatusTool(
            ObjectProvider<RagDocumentMapper> documentMapper,
            ObjectProvider<RagChunkMapper> chunkMapper,
            ObjectProvider<RagEmbeddingTaskMapper> taskMapper
    ) {
        this.documentMapper = documentMapper;
        this.chunkMapper = chunkMapper;
        this.taskMapper = taskMapper;
    }

    @Override public String name() { return "query_rag_status"; }
    @Override public String description() { return "查询 RAG 资料数量、索引和向量化任务状态。"; }
    @Override public Map<String, Object> parameterSchema() { return AgentDrafts.schema(); }
    @Override public Set<AiAgentRole> roles() { return Set.of(AiAgentRole.SUPER_ADMIN); }
    @Override public boolean mutation() { return false; }

    @Override
    public AgentToolResult execute(AgentToolContext context, Map<String, Object> arguments) {
        RagDocumentMapper documents = documentMapper.getIfAvailable();
        RagChunkMapper chunks = chunkMapper.getIfAvailable();
        RagEmbeddingTaskMapper tasks = taskMapper.getIfAvailable();
        if (documents == null || chunks == null || tasks == null) {
            return AgentToolResult.error("RAG 资料服务暂不可用。");
        }
        Map<String, Object> item = new LinkedHashMap<>();
        item.put("documents", documents.selectCount(new QueryWrapper<RagDocument>()));
        item.put("readyDocuments", documents.selectCount(new QueryWrapper<RagDocument>().eq("status", "READY")));
        item.put("chunks", chunks.selectCount(new QueryWrapper<>()));
        item.put("pendingEmbeddings", tasks.selectCount(new QueryWrapper<RagEmbeddingTask>().eq("status", "PENDING")));
        item.put("failedEmbeddings", tasks.selectCount(new QueryWrapper<RagEmbeddingTask>().eq("status", "FAILED")));
        return AgentToolResult.result(
                "当前知识库共 " + item.get("documents") + " 份资料。",
                List.of(item),
                AgentDrafts.navigate("打开 RAG 资料管理", "/admin/ragManagement")
        );
    }
}
