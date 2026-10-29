package finalassignmentbackend.controller.rag;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import finalassignmentbackend.dto.ApiResponse;
import finalassignmentbackend.mapper.RagChunkMapper;
import finalassignmentbackend.mapper.RagDocumentMapper;
import finalassignmentbackend.mapper.RagEmbeddingTaskMapper;
import finalassignmentbackend.rag.config.RagProperties;
import finalassignmentbackend.rag.elasticsearch.RagIndexManager;
import finalassignmentbackend.rag.embedding.RagEmbeddingWorker;
import finalassignmentbackend.rag.entity.RagChunk;
import finalassignmentbackend.rag.entity.RagDocument;
import finalassignmentbackend.rag.entity.RagEmbeddingTask;
import finalassignmentbackend.rag.service.RagBackfillJob;
import finalassignmentbackend.rag.service.RagDocumentDeletionService;
import jakarta.ws.rs.core.Response;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.lang.reflect.Proxy;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * 管理端契约。
 *
 * <p>评测脚本靠 {@code GET /documents?query=...} 找到语料（靠 metadata 里的 suite 标记），
 * 靠 {@code GET /documents/{id}} 读每个分块的嵌入状态，靠 {@code DELETE /documents/{id}}
 * 清理语料。任何一处字段名或过滤条件对不上，评测就会超时或清理不到。
 */
class RagManagementControllerTest {

    private RagManagementController controller;
    private RagProperties properties;
    private FakeIndexManager indexManager;
    private FakeDeletionService deletionService;
    private FakeEmbeddingWorker embeddingWorker;
    private FakeBackfillJob backfillJob;
    private List<RagDocument> documents;
    private List<RagChunk> chunks;
    private List<RagEmbeddingTask> tasks;
    private QueryWrapper<RagDocument> capturedWrapper;

    @BeforeEach
    void setUp() {
        documents = new ArrayList<>();
        chunks = new ArrayList<>();
        tasks = new ArrayList<>();
        capturedWrapper = null;
        properties = new RagProperties();
        indexManager = new FakeIndexManager();
        deletionService = new FakeDeletionService();
        embeddingWorker = new FakeEmbeddingWorker();
        backfillJob = new FakeBackfillJob();
        controller = new RagManagementController();
        controller.ragProperties = properties;
        controller.ragIndexManager = indexManager;
        controller.deletionService = deletionService;
        controller.embeddingWorker = embeddingWorker;
        controller.backfillJob = backfillJob;
        controller.documentMapper = documentMapper();
        controller.chunkMapper = chunkMapper();
        controller.taskMapper = taskMapper();
    }

    @Test
    void documentQueryAlsoMatchesTheMetadataJson() {
        controller.documents("ragas", 1, null, 50);

        assertNotNull(capturedWrapper);
        String segment = capturedWrapper.getCustomSqlSegment();
        assertTrue(segment.contains("metadata_json"), "metadata_json must be searchable: " + segment);
        assertTrue(segment.contains("title"));
        assertTrue(segment.contains("source_id"));
        assertTrue(segment.contains("acl_scope"));
        assertTrue(segment.contains("route"));
        assertTrue(capturedWrapper.getParamNameValuePairs().containsValue("%ragas%"));
    }

    @Test
    void documentQueryWithoutKeywordDoesNotFilter() {
        controller.documents(null, 1, null, 50);

        assertNotNull(capturedWrapper);
        assertFalse(capturedWrapper.getCustomSqlSegment().contains("metadata_json"));
    }

    @Test
    void overviewReportsTheIndexAndEmbeddingState() {
        properties.setEmbeddingEnabled(true);

        Map<String, Object> body = body(controller.overview());

        assertEquals(true, body.get("embeddingEnabled"));
        assertEquals("rag_chunk_quarkus_v1", body.get("indexName"));
        assertEquals("rag_chunk_quarkus_current", body.get("indexAlias"));
        assertEquals(true, body.get("indexExists"));
    }

    @Test
    void overviewSurvivesAnUnreachableElasticsearch() {
        indexManager.failure = new IllegalStateException("elasticsearch unreachable");

        Map<String, Object> body = body(controller.overview());

        assertEquals(false, body.get("indexExists"));
    }

    @Test
    void documentDetailExposesTheEmbeddingMetadataOfEveryChunk() {
        documents.add(document("doc-1"));
        chunks.add(chunk("chunk-1"));
        tasks.add(task("chunk-1", "SUCCEEDED"));

        Map<String, Object> body = body(controller.getDocument("doc-1"));

        @SuppressWarnings("unchecked")
        List<Map<String, Object>> views = (List<Map<String, Object>>) body.get("chunks");
        assertEquals(1, views.size());
        assertEquals("SUCCEEDED", views.get(0).get("embeddingStatus"));
        assertEquals("nomic-embed-text", views.get(0).get("embeddingModel"));
        assertEquals("hash-1", views.get(0).get("embeddingHash"));
        assertNotNull(views.get(0).get("updatedAt"));
    }

    @Test
    void documentDetailWithoutChunksStillAnswers() {
        documents.add(document("doc-1"));

        Map<String, Object> body = body(controller.getDocument("doc-1"));

        assertEquals("doc-1", ((RagDocument) body.get("document")).getId());
        assertTrue(((List<?>) body.get("chunks")).isEmpty());
    }

    @Test
    void deletingADocumentReportsTheRemovedRows() {
        deletionService.result = new RagDocumentDeletionService.DeletionResult(1, 2, 3);

        Map<String, Object> body = body(controller.deleteDocument("doc-1"));

        assertEquals(1, body.get("documents"));
        assertEquals(2, body.get("chunks"));
        assertEquals(3, body.get("tasks"));
        assertEquals("doc-1", deletionService.deletedDocumentId);
    }

    @Test
    void deletingWithoutADocumentIdIsRejected() {
        Response response = controller.deleteDocument("  ");

        assertEquals(Response.Status.BAD_REQUEST.getStatusCode(), response.getStatus());
        assertEquals("INVALID_DOCUMENT_ID", ((ApiResponse<?>) response.getEntity()).errorCode);
    }

    @Test
    void migrationReportsTheIndexState() {
        Map<String, Object> body = body(controller.migrate(null, false, 1000));

        assertEquals(true, body.get("enabled"));
        assertEquals(true, body.get("createdIndex"));
        assertEquals("rag_chunk_quarkus_v1", body.get("indexName"));
        assertEquals("rag_chunk_quarkus_current", body.get("alias"));
        assertEquals(0, body.get("requeuedChunks"));
    }

    @Test
    void migrationToAnotherIndexReportsTheTargetAndCanRequeue() {
        Map<String, Object> body = body(controller.migrate("rag_chunk_quarkus_v2", true, 500));

        assertEquals(true, body.get("createdIndex"));
        assertEquals(true, body.get("aliasSwitched"));
        assertEquals("rag_chunk_quarkus_v2", body.get("indexName"));
        assertEquals(7, body.get("requeuedChunks"));
        assertEquals(3, body.get("requeuedTasks"));
        assertEquals(4, body.get("createdTasks"));
        assertEquals(500, embeddingWorker.requeueLimit);
    }

    @Test
    void migrationIsRejectedWhenElasticsearchIsDisabled() {
        properties.setElasticsearchEnabled(false);

        Response response = controller.migrate(null, false, 1000);

        assertEquals(409, response.getStatus());
        assertEquals("RAG_DISABLED", ((ApiResponse<?>) response.getEntity()).errorCode);
    }

    @Test
    void backfillReportsTheProcessedDocuments() {
        Map<String, Object> body = body(controller.backfill(1, 200));

        assertEquals(5, body.get("processedDocuments"));
        assertEquals(1, body.get("failedDocuments"));
        assertEquals(true, body.get("hasMore"));
        assertEquals(true, body.get("enabled"));
    }

    @Test
    void backfillRunAlsoReportsTheProcessedPages() {
        Map<String, Object> body = body(controller.backfillRun(1, 200, 20));

        assertEquals(9, body.get("processedDocuments"));
        assertEquals(2, body.get("failedDocuments"));
        assertEquals(3, body.get("processedPages"));
        assertEquals(false, body.get("hasMore"));
    }

    @Test
    void backfillIsRejectedWhenRagIsDisabled() {
        properties.setEnabled(false);

        Response response = controller.backfill(1, 200);

        assertEquals(409, response.getStatus());
        assertEquals("RAG_DISABLED", ((ApiResponse<?>) response.getEntity()).errorCode);
    }

    @SuppressWarnings("unchecked")
    private static Map<String, Object> body(Response response) {
        assertEquals(Response.Status.OK.getStatusCode(), response.getStatus());
        ApiResponse<?> api = (ApiResponse<?>) response.getEntity();
        return (Map<String, Object>) api.data;
    }

    private static RagDocument document(String id) {
        RagDocument document = new RagDocument();
        document.setId(id);
        document.setSourceType("MANUAL");
        document.setStatus("READY");
        document.setTitle("缴款期限");
        document.setSourceId("seed-a01-chunk-1");
        document.setAclScope("PUBLIC");
        document.setMetadataJson("{\"suite\":\"ragas\"}");
        return document;
    }

    private static RagChunk chunk(String id) {
        RagChunk chunk = new RagChunk();
        chunk.setId(id);
        chunk.setDocumentId("doc-1");
        chunk.setChunkNo(0);
        chunk.setContent("罚款应当在十五日内缴纳。");
        chunk.setStatus("EMBEDDED");
        chunk.setEmbeddingModel("nomic-embed-text");
        chunk.setEmbeddingHash("hash-1");
        chunk.setCharCount(12);
        chunk.setUpdatedAt(LocalDateTime.of(2026, 10, 30, 9, 0));
        return chunk;
    }

    private static RagEmbeddingTask task(String chunkId, String status) {
        RagEmbeddingTask task = new RagEmbeddingTask();
        task.setId("task-1");
        task.setChunkId(chunkId);
        task.setStatus(status);
        task.setUpdatedAt(LocalDateTime.of(2026, 10, 30, 9, 0));
        return task;
    }

    private RagDocumentMapper documentMapper() {
        return (RagDocumentMapper) Proxy.newProxyInstance(
                RagDocumentMapper.class.getClassLoader(),
                new Class<?>[]{RagDocumentMapper.class},
                (proxy, method, args) -> {
                    switch (method.getName()) {
                        case "selectPage": {
                            capturedWrapper = (QueryWrapper<RagDocument>) args[1];
                            Page<RagDocument> page = new Page<>(1, 50);
                            page.setRecords(documents);
                            page.setTotal(documents.size());
                            return page;
                        }
                        case "selectCount":
                            return (long) documents.size();
                        case "selectById":
                            return documents.stream()
                                    .filter(row -> row.getId().equals(args[0]))
                                    .findFirst()
                                    .orElse(null);
                        default:
                            return null;
                    }
                });
    }

    private RagChunkMapper chunkMapper() {
        return (RagChunkMapper) Proxy.newProxyInstance(
                RagChunkMapper.class.getClassLoader(),
                new Class<?>[]{RagChunkMapper.class},
                (proxy, method, args) -> "selectList".equals(method.getName()) ? chunks : null);
    }

    private RagEmbeddingTaskMapper taskMapper() {
        return (RagEmbeddingTaskMapper) Proxy.newProxyInstance(
                RagEmbeddingTaskMapper.class.getClassLoader(),
                new Class<?>[]{RagEmbeddingTaskMapper.class},
                (proxy, method, args) -> "selectList".equals(method.getName()) ? tasks : null);
    }

    private static final class FakeIndexManager extends RagIndexManager {

        private RuntimeException failure;

        @Override
        public String indexName() {
            return "rag_chunk_quarkus_v1";
        }

        @Override
        public String aliasName() {
            return "rag_chunk_quarkus_current";
        }

        @Override
        public boolean indexExists() {
            if (failure != null) {
                throw failure;
            }
            return true;
        }

        @Override
        public RagIndexManager.IndexState ensureReady() {
            return new RagIndexManager.IndexState(true, true);
        }

        @Override
        public RagIndexManager.MigrationResult migrateToNewIndex(String requestedIndexName) {
            return new RagIndexManager.MigrationResult(true, true, requestedIndexName);
        }
    }

    private static final class FakeEmbeddingWorker extends RagEmbeddingWorker {

        private int requeueLimit;

        @Override
        public RequeueResult requeueAll(int requestedLimit) {
            requeueLimit = requestedLimit;
            return new RequeueResult(7, 3, 4);
        }
    }

    private static final class FakeBackfillJob extends RagBackfillJob {

        private RagBackfillResult result = new RagBackfillResult(5, 1, true, true);
        private RagBackfillRunResult runResult = new RagBackfillRunResult(9, 2, 3, false, true);

        @Override
        public RagBackfillResult runBatch(int page, int size) {
            return result;
        }

        @Override
        public RagBackfillRunResult runBatches(int startPage, int size, int maxPages) {
            return runResult;
        }
    }

    private static final class FakeDeletionService extends RagDocumentDeletionService {

        private RagDocumentDeletionService.DeletionResult result =
                new RagDocumentDeletionService.DeletionResult(0, 0, 0);
        private String deletedDocumentId;

        @Override
        public RagDocumentDeletionService.DeletionResult delete(String documentId) {
            deletedDocumentId = documentId;
            return result;
        }
    }
}
