package com.tutict.finalassignmentcloud.rag.controller;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ObjectNode;
import com.tutict.finalassignmentcloud.rag.support.PageLimits;
import com.tutict.finalassignmentcloud.dto.response.ApiResponse;
import com.tutict.finalassignmentcloud.rag.dto.RagSourceDocument;
import com.tutict.finalassignmentcloud.rag.entity.RagChunk;
import com.tutict.finalassignmentcloud.rag.entity.RagDocument;
import com.tutict.finalassignmentcloud.rag.entity.RagEmbeddingTask;
import com.tutict.finalassignmentcloud.rag.embedding.RagChunkVectorIndexService;
import com.tutict.finalassignmentcloud.rag.embedding.RagEmbeddingService;
import com.tutict.finalassignmentcloud.rag.ingestion.RagUploadedFileParser;
import com.tutict.finalassignmentcloud.rag.indexing.RagBackfillJob;
import com.tutict.finalassignmentcloud.rag.indexing.RagIndexMaintenanceService;
import com.tutict.finalassignmentcloud.rag.mapper.RagChunkMapper;
import com.tutict.finalassignmentcloud.rag.mapper.RagDocumentMapper;
import com.tutict.finalassignmentcloud.rag.mapper.RagEmbeddingTaskMapper;
import com.tutict.finalassignmentcloud.rag.service.RagAdminDocumentSupport;
import com.tutict.finalassignmentcloud.rag.service.RagIndexingService;
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
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.support.TransactionSynchronization;
import org.springframework.transaction.support.TransactionSynchronizationManager;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import java.time.Instant;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/rag/admin")
@Tag(name = "RAG Management", description = "RAG document management APIs")
@SecurityRequirement(name = "bearerAuth")
@RolesAllowed({"SUPER_ADMIN", "ADMIN"})
public class RagManagementController {

    private final RagDocumentMapper documentMapper;
    private final RagChunkMapper chunkMapper;
    private final RagEmbeddingTaskMapper taskMapper;
    private final ObjectProvider<RagIndexingService> indexingServiceProvider;
    private final ObjectProvider<RagBackfillJob> backfillJobProvider;
    private final ObjectProvider<RagUploadedFileParser> uploadedFileParserProvider;
    private final ObjectProvider<RagEmbeddingService> embeddingServiceProvider;
    private final ObjectProvider<RagIndexMaintenanceService> indexMaintenanceServiceProvider;
    private final ObjectProvider<RagChunkVectorIndexService> vectorIndexServiceProvider;
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
            ObjectProvider<RagChunkVectorIndexService> vectorIndexServiceProvider,
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
        this.vectorIndexServiceProvider = vectorIndexServiceProvider;
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


    @GetMapping("/documents/{documentId}")
    @Operation(summary = "Get a RAG document with reconstructed content and chunks")
    public ResponseEntity<ApiResponse<RagDocumentDetailResponse>> getDocument(@PathVariable String documentId) {
        if (documentId == null || documentId.isBlank()) {
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error("INVALID_DOCUMENT_ID", "documentId must not be blank"));
        }
        RagDocument document = documentMapper.selectById(documentId);
        if (document == null) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(ApiResponse.error("DOCUMENT_NOT_FOUND", "RAG document not found"));
        }
        List<RagChunk> chunks = chunkMapper.selectList(
                new QueryWrapper<RagChunk>().eq("document_id", documentId).orderByAsc("chunk_no")
        );
        Map<String, RagEmbeddingTask> tasks = latestTasks(chunks);
        List<RagChunkView> views = new ArrayList<>();
        for (RagChunk chunk : chunks) {
            RagEmbeddingTask task = tasks.get(chunk.getId());
            views.add(new RagChunkView(
                    chunk.getId(),
                    chunk.getChunkNo() == null ? 0 : chunk.getChunkNo(),
                    chunk.getContent(),
                    chunk.getStatus(),
                    chunk.getCharCount(),
                    task == null ? "" : task.getStatus(),
                    task == null ? "" : defaultIfBlank(task.getLastError(), "")
            ));
        }
        return ResponseEntity.ok(ApiResponse.ok(new RagDocumentDetailResponse(
                document,
                RagAdminDocumentSupport.stitchContent(chunks),
                views
        )));
    }

    @PutMapping("/documents/{documentId}")
    @Operation(summary = "Update a RAG document and re-index it")
    @CacheEvict(cacheNames = "ragAdminReadCache", allEntries = true)
    public ResponseEntity<ApiResponse<RagIndexResponse>> updateDocument(
            @PathVariable String documentId,
            @Valid @RequestBody UpdateRagDocumentRequest request
    ) {
        RagIndexingService indexingService = indexingServiceProvider.getIfAvailable();
        if (!ragEnabled || !ragIndexingEnabled || indexingService == null) {
            return ResponseEntity.status(HttpStatus.CONFLICT)
                    .body(ApiResponse.error("RAG_DISABLED", "RAG indexing is not enabled"));
        }
        if (documentId == null || documentId.isBlank()) {
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error("INVALID_DOCUMENT_ID", "documentId must not be blank"));
        }
        RagDocument existing = documentMapper.selectById(documentId);
        if (existing == null) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(ApiResponse.error("DOCUMENT_NOT_FOUND", "RAG document not found"));
        }
        String metadataJson;
        try {
            metadataJson = normalizeMetadataJson(request.metadataJson());
        } catch (IllegalArgumentException error) {
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error("INVALID_METADATA_JSON", error.getMessage()));
        }
        RagSourceDocument source = new RagSourceDocument(
                existing.getSourceType(),
                existing.getSourceTable(),
                existing.getSourceId(),
                existing.getSourceVersion(),
                request.title(),
                request.content(),
                defaultIfBlank(request.aclScope(), existing.getAclScope()),
                request.route() == null ? existing.getRoute() : request.route(),
                metadataJson,
                "content"
        );
        RagIndexingService.RagIndexingResult result = indexingService.index(source);
        return ResponseEntity.ok(ApiResponse.ok(new RagIndexResponse(
                result.document(),
                result.chunks().size(),
                result.embeddingTasks().size()
        )));
    }

    @PostMapping("/preview")
    @Operation(summary = "Preview knowledge-base hits for a simulated role")
    public ResponseEntity<ApiResponse<List<RagPreviewHit>>> preview(@Valid @RequestBody RagPreviewRequest request) {
        String asRole = RagAdminDocumentSupport.normalizePreviewRole(request.asRole());
        String query = request.query() == null ? "" : request.query().trim();
        if (query.isBlank()) {
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error("INVALID_QUERY", "query must not be blank"));
        }
        int topK = request.topK() == null ? 8 : Math.max(1, Math.min(request.topK(), 20));
        List<RagPreviewHit> hits = new ArrayList<>();
        List<RagDocument> knowledgeDocs = documentMapper.selectList(
                new QueryWrapper<RagDocument>().in("source_type", List.of("MANUAL", "UPLOAD"))
        );
        Map<String, RagDocument> documents = new LinkedHashMap<>();
        List<String> allowedIds = new ArrayList<>();
        for (RagDocument document : knowledgeDocs) {
            if (document == null || document.getId() == null || document.getId().isBlank()) {
                continue;
            }
            if (!RagAdminDocumentSupport.isKnowledgeDocument(document)) {
                continue;
            }
            if (!RagAdminDocumentSupport.previewAllows(asRole, document.getAclScope())) {
                continue;
            }
            documents.put(document.getId(), document);
            allowedIds.add(document.getId());
        }
        if (allowedIds.isEmpty()) {
            return ResponseEntity.ok(ApiResponse.ok(List.of()));
        }
        List<RagChunk> chunks = chunkMapper.selectList(
                new QueryWrapper<RagChunk>().in("document_id", allowedIds).orderByAsc("chunk_no")
        );
        for (RagChunk chunk : chunks) {
            RagDocument document = documents.get(chunk.getDocumentId());
            if (document == null) {
                continue;
            }
            boolean contentHit = chunk.getContent() != null
                    && chunk.getContent().toLowerCase(Locale.ROOT).contains(query.toLowerCase(Locale.ROOT));
            boolean titleHit = document.getTitle() != null
                    && document.getTitle().toLowerCase(Locale.ROOT).contains(query.toLowerCase(Locale.ROOT));
            if (!contentHit && !titleHit) {
                continue;
            }
            double score = RagAdminDocumentSupport.keywordScore(query, document.getTitle(), chunk.getContent());
            if (score <= 0) {
                continue;
            }
            hits.add(new RagPreviewHit(
                    document.getId(),
                    document.getTitle(),
                    RagAdminDocumentSupport.snippet(chunk.getContent(), 180),
                    score,
                    defaultIfBlank(document.getRoute(), ""),
                    defaultIfBlank(document.getAclScope(), "PUBLIC"),
                    defaultIfBlank(document.getSourceType(), "")
            ));
        }
        hits.sort(Comparator.comparingDouble(RagPreviewHit::score).reversed());
        if (hits.size() > topK) {
            hits = new ArrayList<>(hits.subList(0, topK));
        }
        return ResponseEntity.ok(ApiResponse.ok(hits));
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
    @Transactional
    @CacheEvict(cacheNames = "ragAdminReadCache", allEntries = true)
    public ResponseEntity<ApiResponse<Map<String, Integer>>> deleteDocument(@PathVariable String documentId) {
        if (documentId == null || documentId.isBlank()) {
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error("INVALID_DOCUMENT_ID", "documentId must not be blank"));
        }
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

        // Best-effort ES removal after the transactional DB delete commits. A failure here never
        // rolls the transaction back: stale ES docs must not block document deletion.
        TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
            @Override
            public void afterCommit() {
                RagChunkVectorIndexService vectorIndexService = vectorIndexServiceProvider.getIfAvailable();
                if (vectorIndexService != null) {
                    vectorIndexService.deleteByDocumentId(documentId);
                }
            }
        });

        return ResponseEntity.ok(ApiResponse.ok(Map.of(
                "documents", deletedDocuments,
                "chunks", deletedChunks,
                "tasks", deletedTasks
        )));
    }


    private Map<String, RagEmbeddingTask> latestTasks(List<RagChunk> chunks) {
        Map<String, RagEmbeddingTask> latest = new LinkedHashMap<>();
        if (chunks == null || chunks.isEmpty()) {
            return latest;
        }
        List<String> chunkIds = new ArrayList<>();
        for (RagChunk chunk : chunks) {
            if (chunk.getId() != null && !chunk.getId().isBlank()) {
                chunkIds.add(chunk.getId());
            }
        }
        if (chunkIds.isEmpty()) {
            return latest;
        }
        List<RagEmbeddingTask> tasks = taskMapper.selectList(
                new QueryWrapper<RagEmbeddingTask>().in("chunk_id", chunkIds)
        );
        for (RagEmbeddingTask task : tasks) {
            if (task.getChunkId() == null || task.getChunkId().isBlank()) {
                continue;
            }
            RagEmbeddingTask chosen = latest.get(task.getChunkId());
            if (chosen == null
                    || (task.getUpdatedAt() != null
                    && (chosen.getUpdatedAt() == null || task.getUpdatedAt().isAfter(chosen.getUpdatedAt())))) {
                latest.put(task.getChunkId(), task);
            }
        }
        return latest;
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


    public record RagDocumentDetailResponse(
            RagDocument document,
            String content,
            List<RagChunkView> chunks
    ) {
    }

    public record RagChunkView(
            String id,
            int chunkNo,
            String content,
            String status,
            Integer charCount,
            String embeddingStatus,
            String lastError
    ) {
    }

    public record UpdateRagDocumentRequest(
            @NotBlank @Size(max = 200) String title,
            @NotBlank @Size(max = 20000) String content,
            String aclScope,
            String route,
            String metadataJson
    ) {
    }

    public record RagPreviewRequest(
            @NotBlank String query,
            String asRole,
            Integer topK
    ) {
    }

    public record RagPreviewHit(
            String documentId,
            String title,
            String snippet,
            double score,
            String route,
            String aclScope,
            String sourceType
    ) {
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

