package com.tutict.finalassignmentbackend.controller.rag;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ObjectNode;
import com.tutict.finalassignmentbackend.common.PageLimits;
import com.tutict.finalassignmentbackend.dto.response.ApiResponse;
import com.tutict.finalassignmentbackend.rag.dto.RagSourceDocument;
import com.tutict.finalassignmentbackend.rag.entity.RagChunk;
import com.tutict.finalassignmentbackend.rag.entity.RagDocument;
import com.tutict.finalassignmentbackend.rag.entity.RagEmbeddingTask;
import com.tutict.finalassignmentbackend.rag.embedding.RagEmbeddingService;
import com.tutict.finalassignmentbackend.rag.ingestion.RagUploadedFileParser;
import com.tutict.finalassignmentbackend.rag.indexing.RagBackfillJob;
import com.tutict.finalassignmentbackend.rag.indexing.RagIndexMaintenanceService;
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
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

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
    private final ObjectProvider<RagUploadedFileParser> uploadedFileParserProvider;
    private final ObjectProvider<RagEmbeddingService> embeddingServiceProvider;
    private final ObjectProvider<RagIndexMaintenanceService> indexMaintenanceServiceProvider;
    private final ObjectMapper objectMapper;
    private final boolean ragEnabled;
    private final boolean ragIndexingEnabled;

    public RagManagementController(
            RagDocumentMapper documentMapper,
            RagChunkMapper chunkMapper,
            RagEmbeddingTaskMapper taskMapper,
            ObjectProvider<RagIndexingService> indexingServiceProvider,
            ObjectProvider<RagBackfillJob> backfillJobProvider,
            ObjectProvider<RagUploadedFileParser> uploadedFileParserProvider,
            ObjectProvider<RagEmbeddingService> embeddingServiceProvider,
            ObjectProvider<RagIndexMaintenanceService> indexMaintenanceServiceProvider,
            ObjectMapper objectMapper,
            @Value("${rag.enabled:false}") boolean ragEnabled,
            @Value("${rag.indexing.enabled:false}") boolean ragIndexingEnabled
    ) {
        this.documentMapper = documentMapper;
        this.chunkMapper = chunkMapper;
        this.taskMapper = taskMapper;
        this.indexingServiceProvider = indexingServiceProvider;
        this.backfillJobProvider = backfillJobProvider;
        this.uploadedFileParserProvider = uploadedFileParserProvider;
        this.embeddingServiceProvider = embeddingServiceProvider;
        this.indexMaintenanceServiceProvider = indexMaintenanceServiceProvider;
        this.objectMapper = objectMapper;
        this.ragEnabled = ragEnabled;
        this.ragIndexingEnabled = ragIndexingEnabled;
    }

    @PostMapping(value = "/documents/upload", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @Operation(summary = "Upload and index a RAG document or table")
    @CacheEvict(cacheNames = "ragAdminReadCache", allEntries = true)
    public ResponseEntity<ApiResponse<RagIndexResponse>> uploadDocument(
            @RequestParam("file") MultipartFile file,
            @RequestParam(required = false) String sourceId,
            @RequestParam(required = false) String sourceVersion,
            @RequestParam(required = false) String title,
            @RequestParam(required = false) String aclScope,
            @RequestParam(required = false) String route,
            @RequestParam(required = false) String metadataJson
    ) {
        RagIndexingService indexingService = indexingServiceProvider.getIfAvailable();
        RagUploadedFileParser uploadedFileParser = uploadedFileParserProvider.getIfAvailable();
        if (!ragEnabled || !ragIndexingEnabled || indexingService == null || uploadedFileParser == null) {
            return ResponseEntity.status(HttpStatus.CONFLICT)
                    .body(ApiResponse.error("RAG_DISABLED", "RAG indexing is not enabled"));
        }

        RagUploadedFileParser.ParsedRagFile parsedFile;
        try {
            parsedFile = uploadedFileParser.parse(file);
        } catch (Exception error) {
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error("INVALID_RAG_UPLOAD", error.getMessage()));
        }
        if (parsedFile.content().isBlank()) {
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error("EMPTY_RAG_UPLOAD", "uploaded file did not contain indexable text"));
        }

        String normalizedMetadata;
        try {
            normalizedMetadata = mergeUploadMetadata(metadataJson, parsedFile);
        } catch (IllegalArgumentException error) {
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error("INVALID_METADATA_JSON", error.getMessage()));
        }

        RagSourceDocument source = new RagSourceDocument(
                "UPLOAD",
                "uploaded_rag_document",
                defaultIfBlank(sourceId, "upload-" + UUID.randomUUID()),
                defaultIfBlank(sourceVersion, "v" + Instant.now().toEpochMilli()),
                defaultIfBlank(title, parsedFile.title()),
                parsedFile.content(),
                defaultIfBlank(aclScope, "PUBLIC"),
                defaultIfBlank(route, ""),
                normalizedMetadata,
                "file"
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

    @GetMapping("/overview")
    @Operation(summary = "Get RAG management overview")
    @Cacheable(cacheNames = "ragAdminReadCache", key = "'overview'")
    public ResponseEntity<ApiResponse<RagOverviewResponse>> overview() {
        RagOverviewResponse response = new RagOverviewResponse(
                ragEnabled,
                ragIndexingEnabled,
                documentMapper.selectCount(new QueryWrapper<>()),
                documentMapper.selectCount(new QueryWrapper<RagDocument>().eq("status", "READY")),
                chunkMapper.selectCount(new QueryWrapper<>()),
                taskMapper.selectCount(new QueryWrapper<RagEmbeddingTask>().eq("status", "PENDING")),
                taskMapper.selectCount(new QueryWrapper<RagEmbeddingTask>().eq("status", "FAILED")),
                taskMapper.selectCount(new QueryWrapper<RagEmbeddingTask>().eq("status", "SUCCEEDED")),
                taskMapper.selectCount(new QueryWrapper<RagEmbeddingTask>().eq("status", "POISONED"))
        );
        return ResponseEntity.ok(ApiResponse.ok(response));
    }

    @GetMapping("/documents")
    @Operation(summary = "List RAG source documents")
    @Cacheable(cacheNames = "ragAdminReadCache", key = "'documents:' + (#query == null ? '' : #query) + ':' + #limit")
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
                    .like("source_id", keyword)
                    .or()
                    .like("acl_scope", keyword)
                    .or()
                    .like("route", keyword)
                    .or()
                    .apply("CAST(metadata_json AS CHAR) LIKE {0}", "%" + keyword + "%"));
        }
        Page<RagDocument> page = documentMapper.selectPage(
                new Page<>(1, normalizeLimit(limit)),
                wrapper
        );
        return ResponseEntity.ok(ApiResponse.ok(page.getRecords()));
    }

    @PostMapping("/documents/manual")
    @Operation(summary = "Index a manually entered RAG document")
    @CacheEvict(cacheNames = "ragAdminReadCache", allEntries = true)
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
        String metadataJson;
        try {
            metadataJson = normalizeMetadataJson(request.metadataJson());
        } catch (IllegalArgumentException error) {
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error("INVALID_METADATA_JSON", error.getMessage()));
        }
        RagSourceDocument source = new RagSourceDocument(
                "MANUAL",
                "manual_rag_document",
                sourceId,
                sourceVersion,
                request.title(),
                request.content(),
                defaultIfBlank(request.aclScope(), "PUBLIC"),
                defaultIfBlank(request.route(), ""),
                metadataJson,
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
    @CacheEvict(cacheNames = "ragAdminReadCache", allEntries = true)
    public ResponseEntity<ApiResponse<RagBackfillJob.RagBackfillResult>> runBackfill(
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "200") int size
    ) {
        RagBackfillJob job = backfillJobProvider.getIfAvailable();
        if (!ragEnabled || !ragIndexingEnabled || job == null) {
            return ResponseEntity.status(HttpStatus.CONFLICT)
                    .body(ApiResponse.error("RAG_DISABLED", "RAG backfill is not enabled"));
        }
        return ResponseEntity.ok(ApiResponse.ok(job.runBatch(PageLimits.normalizePage(page), PageLimits.normalizeBatchSize(size))));
    }

    @PostMapping("/backfill/run")
    @Operation(summary = "Run multiple bounded RAG backfill batches")
    @CacheEvict(cacheNames = "ragAdminReadCache", allEntries = true)
    public ResponseEntity<ApiResponse<RagBackfillJob.RagBackfillRunResult>> runBackfillBatches(
            @RequestParam(defaultValue = "1") int startPage,
            @RequestParam(defaultValue = "200") int size,
            @RequestParam(defaultValue = "20") int maxPages
    ) {
        RagBackfillJob job = backfillJobProvider.getIfAvailable();
        if (!ragEnabled || !ragIndexingEnabled || job == null) {
            return ResponseEntity.status(HttpStatus.CONFLICT)
                    .body(ApiResponse.error("RAG_DISABLED", "RAG backfill is not enabled"));
        }
        return ResponseEntity.ok(ApiResponse.ok(job.runBatches(
                PageLimits.normalizePage(startPage),
                PageLimits.normalizeBatchSize(size),
                PageLimits.normalizeLimit(maxPages, 50)
        )));
    }

    @PostMapping("/embedding/run")
    @Operation(summary = "Run one RAG embedding batch")
    @CacheEvict(cacheNames = "ragAdminReadCache", allEntries = true)
    public ResponseEntity<ApiResponse<RagEmbeddingService.RagEmbeddingBatchResult>> runEmbeddingBatch(
            @RequestParam(defaultValue = "25") int limit
    ) {
        RagEmbeddingService embeddingService = embeddingServiceProvider.getIfAvailable();
        if (!ragEnabled || embeddingService == null) {
            return ResponseEntity.status(HttpStatus.CONFLICT)
                    .body(ApiResponse.error("RAG_EMBEDDING_DISABLED", "RAG embedding is not enabled"));
        }
        return ResponseEntity.ok(ApiResponse.ok(embeddingService.processPendingBatch(PageLimits.normalizeBatchSize(limit))));
    }

    @PostMapping("/embedding/requeue")
    @Operation(summary = "Requeue existing RAG chunks for embedding")
    @CacheEvict(cacheNames = "ragAdminReadCache", allEntries = true)
    public ResponseEntity<ApiResponse<RagIndexMaintenanceService.RequeueResult>> requeueEmbeddingTasks(
            @RequestParam(defaultValue = "1000") int limit
    ) {
        RagIndexMaintenanceService maintenanceService = indexMaintenanceServiceProvider.getIfAvailable();
        if (!ragEnabled || maintenanceService == null) {
            return ResponseEntity.status(HttpStatus.CONFLICT)
                    .body(ApiResponse.error("RAG_MAINTENANCE_DISABLED", "RAG index maintenance is not enabled"));
        }
        return ResponseEntity.ok(ApiResponse.ok(maintenanceService.requeueEmbeddingTasks(PageLimits.normalizeLimit(limit, 1000))));
    }

    @PostMapping("/index/migrate")
    @Operation(summary = "Create a new RAG Elasticsearch index, switch alias, and optionally requeue embeddings")
    @CacheEvict(cacheNames = "ragAdminReadCache", allEntries = true)
    public ResponseEntity<ApiResponse<RagIndexMaintenanceService.RagIndexMigrationResult>> migrateIndex(
            @RequestParam(required = false) String indexName,
            @RequestParam(defaultValue = "true") boolean requeue,
            @RequestParam(defaultValue = "1000") int requeueLimit
    ) {
        RagIndexMaintenanceService maintenanceService = indexMaintenanceServiceProvider.getIfAvailable();
        if (!ragEnabled || maintenanceService == null) {
            return ResponseEntity.status(HttpStatus.CONFLICT)
                    .body(ApiResponse.error("RAG_MAINTENANCE_DISABLED", "RAG index maintenance is not enabled"));
        }
        return ResponseEntity.ok(ApiResponse.ok(
                maintenanceService.migrateToNewIndex(indexName, requeue, PageLimits.normalizeLimit(requeueLimit, 1000))
        ));
    }

    @DeleteMapping("/documents/{documentId}")
    @Operation(summary = "Delete a RAG source document and its chunks")
    @CacheEvict(cacheNames = "ragAdminReadCache", allEntries = true)
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
        return PageLimits.normalizeLimit(limit);
    }

    private static String defaultIfBlank(String value, String fallback) {
        return value == null || value.isBlank() ? fallback : value.trim();
    }

    private String normalizeMetadataJson(String value) {
        String normalized = defaultIfBlank(value, "{}");
        try {
            JsonNode node = objectMapper.readTree(normalized);
            if (!node.isObject()) {
                throw new IllegalArgumentException("metadataJson must be a JSON object");
            }
            return objectMapper.writeValueAsString(node);
        } catch (JsonProcessingException error) {
            throw new IllegalArgumentException("metadataJson is not valid JSON", error);
        }
    }

    private String mergeUploadMetadata(String value, RagUploadedFileParser.ParsedRagFile parsedFile) {
        String normalized = defaultIfBlank(value, "{}");
        try {
            JsonNode node = objectMapper.readTree(normalized);
            if (!node.isObject()) {
                throw new IllegalArgumentException("metadataJson must be a JSON object");
            }
            ObjectNode objectNode = (ObjectNode) node.deepCopy();
            objectNode.put("ingestMode", "upload");
            objectNode.put("fileName", parsedFile.fileName());
            objectNode.put("contentType", defaultIfBlank(parsedFile.contentType(), "application/octet-stream"));
            objectNode.put("fileSize", parsedFile.size());
            objectNode.put("parser", parsedFile.parser());
            if (parsedFile.rowCount() > 0) {
                objectNode.put("rowCount", parsedFile.rowCount());
            }
            if (parsedFile.sheetCount() > 0) {
                if ("pdf".equalsIgnoreCase(parsedFile.parser())) {
                    objectNode.put("pageCount", parsedFile.sheetCount());
                } else {
                    objectNode.put("sheetCount", parsedFile.sheetCount());
                }
            }
            return objectMapper.writeValueAsString(objectNode);
        } catch (JsonProcessingException error) {
            throw new IllegalArgumentException("metadataJson is not valid JSON", error);
        }
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
            long failedEmbeddingTaskCount,
            long succeededEmbeddingTaskCount,
            long poisonedEmbeddingTaskCount
    ) {
    }

    public record RagIndexResponse(
            RagDocument document,
            int chunkCount,
            int embeddingTaskCount
    ) {
    }
}
