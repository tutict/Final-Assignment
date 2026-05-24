package com.tutict.finalassignmentbackend.controller;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.tutict.finalassignmentbackend.dto.response.ApiResponse;
import com.tutict.finalassignmentbackend.rag.dto.RagSourceDocument;
import com.tutict.finalassignmentbackend.rag.entity.RagChunk;
import com.tutict.finalassignmentbackend.rag.entity.RagDocument;
import com.tutict.finalassignmentbackend.rag.entity.RagEmbeddingTask;
import com.tutict.finalassignmentbackend.rag.indexing.RagBackfillJob;
import com.tutict.finalassignmentbackend.rag.mapper.RagChunkMapper;
import com.tutict.finalassignmentbackend.rag.mapper.RagDocumentMapper;
import com.tutict.finalassignmentbackend.rag.mapper.RagEmbeddingTaskMapper;
import com.tutict.finalassignmentbackend.rag.service.RagIndexingService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.annotation.security.RolesAllowed;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/rag/admin")
@Tag(name = "RAG Management", description = "RAG document management APIs")
@SecurityRequirement(name = "bearerAuth")
@RolesAllowed({"SUPER_ADMIN"})
public class RagManagementController {

    private final RagDocumentMapper documentMapper;
    private final RagChunkMapper chunkMapper;
    private final RagEmbeddingTaskMapper taskMapper;
    private final ObjectProvider<RagIndexingService> indexingServiceProvider;
    private final ObjectProvider<RagBackfillJob> backfillJobProvider;
    private final boolean ragEnabled;
    private final boolean ragIndexingEnabled;

    public RagManagementController(
            RagDocumentMapper documentMapper,
            RagChunkMapper chunkMapper,
            RagEmbeddingTaskMapper taskMapper,
            ObjectProvider<RagIndexingService> indexingServiceProvider,
            ObjectProvider<RagBackfillJob> backfillJobProvider,
            @Value("${rag.enabled:false}") boolean ragEnabled,
            @Value("${rag.indexing.enabled:false}") boolean ragIndexingEnabled
    ) {
        this.documentMapper = documentMapper;
        this.chunkMapper = chunkMapper;
        this.taskMapper = taskMapper;
        this.indexingServiceProvider = indexingServiceProvider;
        this.backfillJobProvider = backfillJobProvider;
        this.ragEnabled = ragEnabled;
        this.ragIndexingEnabled = ragIndexingEnabled;
    }

    @GetMapping("/overview")
    @Operation(summary = "Get RAG management overview")
    public ResponseEntity<ApiResponse<RagOverviewResponse>> overview() {
        RagOverviewResponse response = new RagOverviewResponse(
                ragEnabled,
                ragIndexingEnabled,
                documentMapper.selectCount(new QueryWrapper<>()),
                documentMapper.selectCount(new QueryWrapper<RagDocument>().eq("status", "READY")),
                chunkMapper.selectCount(new QueryWrapper<>()),
                taskMapper.selectCount(new QueryWrapper<RagEmbeddingTask>().eq("status", "PENDING")),
                taskMapper.selectCount(new QueryWrapper<RagEmbeddingTask>().eq("status", "FAILED"))
        );
        return ResponseEntity.ok(ApiResponse.ok(response));
    }

    @GetMapping("/documents")
    @Operation(summary = "List RAG source documents")
    public ResponseEntity<ApiResponse<List<RagDocument>>> listDocuments(
            @RequestParam(required = false) String query,
            @RequestParam(defaultValue = "50") int limit
    ) {
        QueryWrapper<RagDocument> wrapper = new QueryWrapper<RagDocument>()
                .orderByDesc("updated_at");
        if (query != null && !query.isBlank()) {
            String keyword = query.trim();
            wrapper.and(nested -> nested
                    .like("title", keyword)
                    .or()
                    .like("source_table", keyword)
                    .or()
                    .like("source_id", keyword));
        }
        Page<RagDocument> page = documentMapper.selectPage(
                new Page<>(1, normalizeLimit(limit)),
                wrapper
        );
        return ResponseEntity.ok(ApiResponse.ok(page.getRecords()));
    }

    @PostMapping("/documents/manual")
    @Operation(summary = "Index a manually entered RAG document")
    public ResponseEntity<ApiResponse<RagIndexResponse>> createManualDocument(
            @Valid @RequestBody ManualRagDocumentRequest request
    ) {
        RagIndexingService indexingService = indexingServiceProvider.getIfAvailable();
        if (!ragEnabled || !ragIndexingEnabled || indexingService == null) {
            return ResponseEntity.status(HttpStatus.CONFLICT)
                    .body(ApiResponse.error("RAG_DISABLED", "RAG indexing is not enabled"));
        }

        String sourceId = defaultIfBlank(request.sourceId(), "manual-" + UUID.randomUUID());
        String sourceVersion = defaultIfBlank(request.sourceVersion(), "v" + Instant.now().toEpochMilli());
        RagSourceDocument source = new RagSourceDocument(
                "MANUAL",
                "manual_rag_document",
                sourceId,
                sourceVersion,
                request.title(),
                request.content(),
                defaultIfBlank(request.aclScope(), "PUBLIC"),
                defaultIfBlank(request.route(), ""),
                defaultIfBlank(request.metadataJson(), "{}"),
                "content"
        );
        RagIndexingService.RagIndexingResult result = indexingService.index(source);
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.ok(
                new RagIndexResponse(
                        result.document(),
                        result.chunks().size(),
                        result.embeddingTasks().size()
                )
        ));
    }

    @PostMapping("/backfill")
    @Operation(summary = "Run one RAG backfill batch")
    public ResponseEntity<ApiResponse<RagBackfillJob.RagBackfillResult>> runBackfill(
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "200") int size
    ) {
        RagBackfillJob job = backfillJobProvider.getIfAvailable();
        if (!ragEnabled || !ragIndexingEnabled || job == null) {
            return ResponseEntity.status(HttpStatus.CONFLICT)
                    .body(ApiResponse.error("RAG_DISABLED", "RAG backfill is not enabled"));
        }
        return ResponseEntity.ok(ApiResponse.ok(job.runBatch(page, size)));
    }

    @DeleteMapping("/documents/{documentId}")
    @Operation(summary = "Delete a RAG source document and its chunks")
    public ResponseEntity<ApiResponse<Map<String, Integer>>> deleteDocument(@PathVariable String documentId) {
        List<RagChunk> chunks = chunkMapper.selectList(
                new QueryWrapper<RagChunk>().eq("document_id", documentId)
        );
        int deletedTasks = 0;
        for (RagChunk chunk : chunks) {
            deletedTasks += taskMapper.delete(
                    new QueryWrapper<RagEmbeddingTask>().eq("chunk_id", chunk.getId())
            );
        }
        int deletedChunks = chunkMapper.delete(new QueryWrapper<RagChunk>().eq("document_id", documentId));
        int deletedDocuments = documentMapper.deleteById(documentId);
        return ResponseEntity.ok(ApiResponse.ok(Map.of(
                "documents", deletedDocuments,
                "chunks", deletedChunks,
                "tasks", deletedTasks
        )));
    }

    private static int normalizeLimit(int limit) {
        return Math.min(Math.max(limit, 1), 200);
    }

    private static String defaultIfBlank(String value, String fallback) {
        return value == null || value.isBlank() ? fallback : value.trim();
    }

    public record ManualRagDocumentRequest(
            String sourceId,
            String sourceVersion,
            @NotBlank @Size(max = 200) String title,
            @NotBlank @Size(max = 20000) String content,
            String aclScope,
            String route,
            String metadataJson
    ) {
    }

    public record RagOverviewResponse(
            boolean ragEnabled,
            boolean indexingEnabled,
            long documentCount,
            long readyDocumentCount,
            long chunkCount,
            long pendingEmbeddingTaskCount,
            long failedEmbeddingTaskCount
    ) {
    }

    public record RagIndexResponse(
            RagDocument document,
            int chunkCount,
            int embeddingTaskCount
    ) {
    }
}
