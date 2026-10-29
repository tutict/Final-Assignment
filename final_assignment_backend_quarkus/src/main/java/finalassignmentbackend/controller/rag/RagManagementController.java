package finalassignmentbackend.controller.rag;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import finalassignmentbackend.dto.ApiResponse;
import finalassignmentbackend.mapper.RagChunkMapper;
import finalassignmentbackend.mapper.RagDocumentMapper;
import finalassignmentbackend.mapper.RagEmbeddingTaskMapper;
import finalassignmentbackend.rag.config.RagProperties;
import finalassignmentbackend.rag.dto.RagSourceDocument;
import finalassignmentbackend.rag.elasticsearch.ElasticsearchException;
import finalassignmentbackend.rag.elasticsearch.RagIndexManager;
import finalassignmentbackend.rag.embedding.RagEmbeddingWorker;
import finalassignmentbackend.rag.entity.RagChunk;
import finalassignmentbackend.rag.entity.RagDocument;
import finalassignmentbackend.rag.entity.RagEmbeddingTask;
import finalassignmentbackend.rag.service.RagAdminDocumentSupport;
import finalassignmentbackend.rag.service.RagDocumentDeletionService;
import finalassignmentbackend.rag.service.RagIndexingService;
import io.smallrye.common.annotation.RunOnVirtualThread;
import jakarta.annotation.security.RolesAllowed;
import jakarta.inject.Inject;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.DELETE;
import jakarta.ws.rs.DefaultValue;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.PUT;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.PathParam;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.QueryParam;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import org.jboss.resteasy.reactive.RestForm;
import org.jboss.resteasy.reactive.multipart.FileUpload;

import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import finalassignmentbackend.rag.ingestion.RagUploadTextExtractor;
import java.util.Map;
import java.util.UUID;
import java.util.logging.Level;
import java.util.logging.Logger;

@Path("/api/rag/admin")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
@RolesAllowed({"SUPER_ADMIN", "ADMIN"})
public class RagManagementController {

    private static final Logger LOG = Logger.getLogger(RagManagementController.class.getName());

    @Inject RagDocumentMapper documentMapper;
    @Inject RagChunkMapper chunkMapper;
    @Inject RagEmbeddingTaskMapper taskMapper;
    @Inject RagIndexingService indexingService;
    @Inject RagProperties ragProperties;
    @Inject RagIndexManager ragIndexManager;
    @Inject RagEmbeddingWorker embeddingWorker;
    @Inject RagDocumentDeletionService deletionService;

    @GET
    @Path("/overview")
    @RunOnVirtualThread
    public Response overview() {
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("ragEnabled", ragProperties.isEnabled());
        body.put("indexingEnabled", ragProperties.isIndexingEnabled());
        body.put("embeddingEnabled", ragProperties.isEmbeddingEnabled());
        body.put("documentCount", documentMapper.selectCount(new QueryWrapper<>()));
        body.put("readyDocumentCount", documentMapper.selectCount(new QueryWrapper<RagDocument>().eq("status", "READY")));
        body.put("chunkCount", chunkMapper.selectCount(new QueryWrapper<>()));
        body.put("pendingEmbeddingTaskCount", taskMapper.selectCount(new QueryWrapper<RagEmbeddingTask>().eq("status", "PENDING")));
        body.put("failedEmbeddingTaskCount", taskMapper.selectCount(new QueryWrapper<RagEmbeddingTask>().eq("status", "FAILED")));
        body.put("succeededEmbeddingTaskCount", taskMapper.selectCount(new QueryWrapper<RagEmbeddingTask>().eq("status", "SUCCEEDED")));
        body.put("poisonedEmbeddingTaskCount", taskMapper.selectCount(new QueryWrapper<RagEmbeddingTask>().eq("status", "POISONED")));
        body.put("indexName", ragIndexManager.indexName());
        body.put("indexAlias", ragIndexManager.aliasName());
        // ES 不可达时只报告索引不存在，绝不让概览接口整体失败。
        body.put("indexExists", ragProperties.isElasticsearchEnabled() && indexExists());
        return Response.ok(ApiResponse.ok(body)).build();
    }

    @GET
    @Path("/documents")
    @RunOnVirtualThread
    public Response documents(@QueryParam("query") String query,
                              @QueryParam("page") @DefaultValue("1") int page,
                              @QueryParam("size") Integer size,
                              @QueryParam("limit") @DefaultValue("50") int limit) {
        int pageNo = Math.max(1, page);
        int pageSize = Math.max(1, Math.min(size != null ? size : limit, 200));
        QueryWrapper<RagDocument> wrapper = new QueryWrapper<RagDocument>().orderByDesc("updated_at");
        if (query != null && !query.isBlank()) {
            String keyword = query.trim();
            // metadata_json 必须一起匹配：评测语料靠 metadata 里的 suite 标记识别。
            wrapper.and(nested -> nested
                    .like("title", keyword)
                    .or().like("source_table", keyword)
                    .or().like("source_id", keyword)
                    .or().like("acl_scope", keyword)
                    .or().like("route", keyword)
                    .or().apply("CAST(metadata_json AS CHAR) LIKE {0}", "%" + keyword + "%"));
        }
        Page<RagDocument> result = documentMapper.selectPage(new Page<>(pageNo, pageSize), wrapper);
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("items", result.getRecords());
        body.put("total", result.getTotal());
        body.put("page", pageNo);
        body.put("size", pageSize);
        return Response.ok(ApiResponse.ok(body)).build();
    }

    @GET
    @Path("/documents/{documentId}")
    @RunOnVirtualThread
    public Response getDocument(@PathParam("documentId") String documentId) {
        if (documentId == null || documentId.isBlank()) {
            return Response.status(Response.Status.BAD_REQUEST).entity(ApiResponse.error("INVALID_DOCUMENT_ID", "documentId must not be blank")).build();
        }
        RagDocument document = documentMapper.selectById(documentId);
        if (document == null) {
            return Response.status(Response.Status.NOT_FOUND).entity(ApiResponse.error("DOCUMENT_NOT_FOUND", "RAG document not found")).build();
        }
        List<RagChunk> chunks = chunkMapper.selectList(new QueryWrapper<RagChunk>().eq("document_id", documentId).orderByAsc("chunk_no"));
        Map<String, RagEmbeddingTask> tasks = latestTasks(chunks);
        List<Map<String, Object>> views = new ArrayList<>();
        for (RagChunk chunk : chunks) {
            RagEmbeddingTask task = tasks.get(chunk.getId());
            Map<String, Object> view = new LinkedHashMap<>();
            view.put("id", chunk.getId());
            view.put("chunkNo", chunk.getChunkNo() == null ? 0 : chunk.getChunkNo());
            view.put("content", chunk.getContent());
            view.put("status", chunk.getStatus());
            view.put("charCount", chunk.getCharCount());
            view.put("embeddingStatus", task == null ? "" : task.getStatus());
            view.put("lastError", task == null ? "" : defaultIfBlank(task.getLastError(), ""));
            view.put("embeddingModel", defaultIfBlank(chunk.getEmbeddingModel(), ""));
            view.put("embeddingHash", defaultIfBlank(chunk.getEmbeddingHash(), ""));
            view.put("updatedAt", chunk.getUpdatedAt());
            views.add(view);
        }
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("document", document);
        body.put("content", RagAdminDocumentSupport.stitchContent(chunks));
        body.put("chunks", views);
        return Response.ok(ApiResponse.ok(body)).build();
    }

    @PUT
    @Path("/documents/{documentId}")
    @RunOnVirtualThread
    public Response updateDocument(@PathParam("documentId") String documentId, Map<String, Object> request) {
        if (!ragProperties.isEnabled() || !ragProperties.isIndexingEnabled()) {
            return Response.status(409).entity(ApiResponse.error("RAG_DISABLED", "RAG indexing is not enabled")).build();
        }
        RagDocument existing = documentMapper.selectById(documentId);
        if (existing == null) {
            return Response.status(Response.Status.NOT_FOUND).entity(ApiResponse.error("DOCUMENT_NOT_FOUND", "RAG document not found")).build();
        }
        String title = str(request, "title");
        String content = str(request, "content");
        if (title.isBlank() || content.isBlank()) {
            return Response.status(Response.Status.BAD_REQUEST).entity(ApiResponse.error("INVALID_REQUEST", "title and content are required")).build();
        }
        RagIndexingService.RagIndexingResult result = indexingService.index(new RagSourceDocument(
                existing.getSourceType(), existing.getSourceTable(), existing.getSourceId(), existing.getSourceVersion(),
                title, content, defaultIfBlank(str(request, "aclScope"), existing.getAclScope()),
                request.get("route") == null ? existing.getRoute() : str(request, "route"),
                defaultIfBlank(str(request, "metadataJson"), "{}"), "content"));
        return Response.ok(ApiResponse.ok(indexBody(result))).build();
    }

    @POST
    @Path("/preview")
    @RunOnVirtualThread
    public Response preview(Map<String, Object> request) {
        String query = str(request, "query");
        if (query.isBlank()) {
            return Response.status(Response.Status.BAD_REQUEST).entity(ApiResponse.error("INVALID_QUERY", "query must not be blank")).build();
        }
        String asRole = RagAdminDocumentSupport.normalizePreviewRole(str(request, "asRole"));
        int topK = 8;
        if (request.get("topK") instanceof Number number) {
            topK = Math.max(1, Math.min(number.intValue(), 20));
        }
        List<RagDocument> knowledgeDocs = documentMapper.selectList(new QueryWrapper<RagDocument>().in("source_type", List.of("MANUAL", "UPLOAD")));
        Map<String, RagDocument> documents = new LinkedHashMap<>();
        List<String> allowedIds = new ArrayList<>();
        for (RagDocument document : knowledgeDocs) {
            if (!RagAdminDocumentSupport.isKnowledgeDocument(document) || !RagAdminDocumentSupport.previewAllows(asRole, document.getAclScope())) {
                continue;
            }
            documents.put(document.getId(), document);
            allowedIds.add(document.getId());
        }
        if (allowedIds.isEmpty()) {
            return Response.ok(ApiResponse.ok(List.of())).build();
        }
        List<Map<String, Object>> hits = new ArrayList<>();
        List<RagChunk> chunks = chunkMapper.selectList(new QueryWrapper<RagChunk>().in("document_id", allowedIds).orderByAsc("chunk_no"));
        for (RagChunk chunk : chunks) {
            RagDocument document = documents.get(chunk.getDocumentId());
            if (document == null) continue;
            boolean contentHit = chunk.getContent() != null && chunk.getContent().toLowerCase(Locale.ROOT).contains(query.toLowerCase(Locale.ROOT));
            boolean titleHit = document.getTitle() != null && document.getTitle().toLowerCase(Locale.ROOT).contains(query.toLowerCase(Locale.ROOT));
            if (!contentHit && !titleHit) continue;
            double score = RagAdminDocumentSupport.keywordScore(query, document.getTitle(), chunk.getContent());
            if (score <= 0) continue;
            Map<String, Object> hit = new LinkedHashMap<>();
            hit.put("documentId", document.getId());
            hit.put("title", document.getTitle());
            hit.put("snippet", RagAdminDocumentSupport.snippet(chunk.getContent(), 180));
            hit.put("score", score);
            hit.put("route", defaultIfBlank(document.getRoute(), ""));
            hit.put("aclScope", defaultIfBlank(document.getAclScope(), "PUBLIC"));
            hit.put("sourceType", defaultIfBlank(document.getSourceType(), ""));
            hits.add(hit);
        }
        hits.sort(Comparator.comparingDouble(item -> -((Number) item.get("score")).doubleValue()));
        if (hits.size() > topK) hits = new ArrayList<>(hits.subList(0, topK));
        return Response.ok(ApiResponse.ok(hits)).build();
    }

    @POST
    @Path("/documents/manual")
    @RunOnVirtualThread
    public Response createManualDocument(Map<String, Object> request) {
        if (!ragProperties.isEnabled() || !ragProperties.isIndexingEnabled()) {
            return Response.status(409).entity(ApiResponse.error("RAG_DISABLED", "RAG indexing is not enabled")).build();
        }
        String title = str(request, "title");
        String content = str(request, "content");
        if (title.isBlank() || content.isBlank()) {
            return Response.status(Response.Status.BAD_REQUEST).entity(ApiResponse.error("INVALID_REQUEST", "title and content are required")).build();
        }
        String sourceId = defaultIfBlank(str(request, "sourceId"), "manual-" + UUID.randomUUID());
        String sourceVersion = defaultIfBlank(str(request, "sourceVersion"), "v" + Instant.now().toEpochMilli());
        RagIndexingService.RagIndexingResult result = indexingService.index(new RagSourceDocument(
                "MANUAL", "manual_rag_document", sourceId, sourceVersion, title, content,
                defaultIfBlank(str(request, "aclScope"), "PUBLIC"), str(request, "route"),
                defaultIfBlank(str(request, "metadataJson"), "{}"), "content"));
        return Response.ok(ApiResponse.ok(indexBody(result))).build();
    }

    @POST
    @Path("/documents/upload")
    @Consumes(MediaType.MULTIPART_FORM_DATA)
    @RunOnVirtualThread
    public Response uploadDocument(@RestForm("title") String title, @RestForm("content") String content,
                                   @RestForm("aclScope") String aclScope, @RestForm("route") String route,
                                   @RestForm("metadataJson") String metadataJson, @RestForm("file") FileUpload file) {
        if (!ragProperties.isEnabled() || !ragProperties.isIndexingEnabled()) {
            return Response.status(409).entity(ApiResponse.error("RAG_DISABLED", "RAG indexing is not enabled")).build();
        }
        String body = content == null ? "" : content;
        if ((body.isBlank()) && file != null && file.uploadedFile() != null) {
            try {
                body = RagUploadTextExtractor.extract(file.uploadedFile(), file.fileName());
            } catch (IllegalArgumentException ex) {
                return Response.status(Response.Status.BAD_REQUEST).entity(ApiResponse.error("INVALID_UPLOAD", ex.getMessage())).build();
            } catch (Exception ex) {
                return Response.status(Response.Status.BAD_REQUEST).entity(ApiResponse.error("INVALID_UPLOAD", "unable to read uploaded file")).build();
            }
        }
        String resolvedTitle = defaultIfBlank(title, file == null ? "upload" : file.fileName());
        if (resolvedTitle.isBlank() || body.isBlank()) {
            return Response.status(Response.Status.BAD_REQUEST).entity(ApiResponse.error("INVALID_REQUEST", "title and content are required")).build();
        }
        RagIndexingService.RagIndexingResult result = indexingService.index(new RagSourceDocument(
                "UPLOAD", "uploaded_rag_document", "upload-" + UUID.randomUUID(), "v" + Instant.now().toEpochMilli(),
                resolvedTitle, body, defaultIfBlank(aclScope, "PUBLIC"), defaultIfBlank(route, ""),
                defaultIfBlank(metadataJson, "{}"), "content"));
        return Response.ok(ApiResponse.ok(indexBody(result))).build();
    }

    @DELETE
    @Path("/documents/{documentId}")
    @RunOnVirtualThread
    public Response deleteDocument(@PathParam("documentId") String documentId) {
        if (documentId == null || documentId.isBlank()) {
            return Response.status(Response.Status.BAD_REQUEST).entity(ApiResponse.error("INVALID_DOCUMENT_ID", "documentId must not be blank")).build();
        }
        RagDocumentDeletionService.DeletionResult result = deletionService.delete(documentId);
        return Response.ok(ApiResponse.ok(Map.of(
                "documents", result.documents(),
                "chunks", result.chunks(),
                "tasks", result.tasks()
        ))).build();
    }

    @POST
    @Path("/backfill")
    @RunOnVirtualThread
    public Response backfill() {
        return Response.ok(ApiResponse.ok(Map.of("processedDocuments", 0, "failedDocuments", 0, "hasMore", false, "enabled", ragProperties.isIndexingEnabled()))).build();
    }

    @POST
    @Path("/backfill/run")
    @Consumes(MediaType.WILDCARD)
    @RunOnVirtualThread
    public Response backfillRun() {
        return Response.ok(ApiResponse.ok(Map.of("processedDocuments", 0, "failedDocuments", 0, "processedPages", 0, "hasMore", false, "enabled", ragProperties.isIndexingEnabled()))).build();
    }

    @POST
    @Path("/embedding/run")
    @Consumes(MediaType.WILDCARD)
    @RunOnVirtualThread
    public Response embeddingRun(@QueryParam("limit") @DefaultValue("50") int limit) {
        RagEmbeddingWorker.EmbeddingBatchResult result = embeddingWorker.processPendingBatch(limit);
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("selectedTasks", result.selectedTasks());
        body.put("succeededTasks", result.succeededTasks());
        body.put("failedTasks", result.failedTasks());
        body.put("enabled", result.enabled());
        body.put("alreadyRunning", result.alreadyRunning());
        body.put("hasMore", result.hasMore());
        return Response.ok(ApiResponse.ok(body)).build();
    }

    @POST
    @Path("/embedding/requeue")
    @RunOnVirtualThread
    public Response embeddingRequeue(@QueryParam("limit") @DefaultValue("100") int limit) {
        RagEmbeddingWorker.RequeueResult result = embeddingWorker.requeue(limit);
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("requeuedChunks", result.requeuedChunks());
        body.put("requeuedTasks", result.requeuedTasks());
        body.put("createdTasks", result.createdTasks());
        return Response.ok(ApiResponse.ok(body)).build();
    }

    @POST
    @Path("/index/migrate")
    @RunOnVirtualThread
    public Response migrate() {
        if (!ragProperties.isEnabled() || !ragProperties.isElasticsearchEnabled()) {
            return Response.status(409).entity(ApiResponse.error("RAG_DISABLED", "RAG indexing is not enabled")).build();
        }
        try {
            RagIndexManager.IndexState state = ragIndexManager.ensureReady();
            Map<String, Object> body = new LinkedHashMap<>();
            body.put("enabled", true);
            body.put("createdIndex", state.createdIndex());
            body.put("aliasSwitched", state.aliasSwitched());
            body.put("indexName", ragIndexManager.indexName());
            body.put("alias", ragIndexManager.aliasName());
            body.put("message", "Elasticsearch index and alias are ready; documents are written by the embedding worker.");
            return Response.ok(ApiResponse.ok(body)).build();
        } catch (ElasticsearchException error) {
            return Response.status(503).entity(ApiResponse.error("ELASTICSEARCH_UNAVAILABLE", error.getMessage())).build();
        }
    }

    /** 探测索引是否存在；任何探测失败都按「不存在」处理，概览接口不能因此挂掉。 */
    private boolean indexExists() {
        try {
            return ragIndexManager.indexExists();
        } catch (RuntimeException error) {
            LOG.log(Level.WARNING, "Failed to probe the RAG index in Elasticsearch", error);
            return false;
        }
    }

    private Map<String, RagEmbeddingTask> latestTasks(List<RagChunk> chunks) {
        Map<String, RagEmbeddingTask> latest = new LinkedHashMap<>();
        List<String> ids = chunks.stream().map(RagChunk::getId).filter(id -> id != null && !id.isBlank()).toList();
        if (ids.isEmpty()) return latest;
        for (RagEmbeddingTask task : taskMapper.selectList(new QueryWrapper<RagEmbeddingTask>().in("chunk_id", ids))) {
            RagEmbeddingTask chosen = latest.get(task.getChunkId());
            if (chosen == null || (task.getUpdatedAt() != null && (chosen.getUpdatedAt() == null || task.getUpdatedAt().isAfter(chosen.getUpdatedAt())))) {
                latest.put(task.getChunkId(), task);
            }
        }
        return latest;
    }

    private static Map<String, Object> indexBody(RagIndexingService.RagIndexingResult result) {
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("document", result.document());
        body.put("chunkCount", result.chunks().size());
        body.put("embeddingTaskCount", result.embeddingTasks().size());
        return body;
    }

    private static String str(Map<String, Object> request, String key) {
        if (request == null || request.get(key) == null) return "";
        return String.valueOf(request.get(key)).trim();
    }

    private static String defaultIfBlank(String value, String fallback) {
        return value == null || value.isBlank() ? fallback : value.trim();
    }
}
