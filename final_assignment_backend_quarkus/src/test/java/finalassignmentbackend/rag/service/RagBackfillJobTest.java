package finalassignmentbackend.rag.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import finalassignmentbackend.mapper.RagChunkMapper;
import finalassignmentbackend.mapper.RagDocumentMapper;
import finalassignmentbackend.rag.config.RagProperties;
import finalassignmentbackend.rag.embedding.RagEmbeddingProvider;
import finalassignmentbackend.rag.embedding.RagEmbeddingStatus;
import finalassignmentbackend.rag.embedding.RagEmbeddingTaskStore;
import finalassignmentbackend.rag.entity.RagChunk;
import finalassignmentbackend.rag.entity.RagDocument;
import finalassignmentbackend.rag.entity.RagEmbeddingTask;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.lang.reflect.Proxy;
import java.time.Duration;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * 回填契约。
 *
 * <p>回填的语义是「让知识文档的分块重新排队等嵌入」：没有任务的分块要补一条任务，
 * 已经嵌入好的分块不动，因此回填可以反复执行而不产生副作用。
 */
class RagBackfillJobTest {

    private RagProperties properties;
    private FakeStore store;
    private RagBackfillJob job;
    private List<RagDocument> documents;
    private List<RagChunk> chunks;
    private String failureDocumentId;

    @BeforeEach
    void setUp() {
        properties = new RagProperties();
        store = new FakeStore();
        documents = new ArrayList<>();
        chunks = new ArrayList<>();
        job = new RagBackfillJob();
        job.documentMapper = documentMapper();
        job.chunkMapper = chunkMapper();
        job.store = store;
        job.provider = new FakeProvider();
        job.properties = properties;
    }

    @Test
    void chunksWithoutATaskGetOneCreated() {
        documents.add(document("doc-1"));
        chunks.add(chunk("chunk-1", "doc-1", RagEmbeddingStatus.CHUNK_PENDING_EMBEDDING));

        RagBackfillJob.RagBackfillResult result = job.runBatch(1, 200);

        assertEquals(1, result.processedDocuments());
        assertEquals(0, result.failedDocuments());
        assertTrue(result.enabled());
        assertEquals(List.of("chunk-1"), store.createdTasks);
        assertEquals(RagEmbeddingStatus.CHUNK_PENDING_EMBEDDING, chunks.get(0).getStatus());
    }

    @Test
    void alreadyEmbeddedChunksAreNotRequeued() {
        documents.add(document("doc-1"));
        chunks.add(chunk("chunk-1", "doc-1", RagEmbeddingStatus.CHUNK_EMBEDDED));

        job.runBatch(1, 200);

        assertTrue(store.createdTasks.isEmpty());
        assertTrue(store.resetChunks.isEmpty());
        assertEquals(RagEmbeddingStatus.CHUNK_EMBEDDED, chunks.get(0).getStatus());
    }

    @Test
    void anExistingTaskIsResetInsteadOfDuplicated() {
        documents.add(document("doc-1"));
        chunks.add(chunk("chunk-1", "doc-1", RagEmbeddingStatus.CHUNK_PENDING_EMBEDDING));
        store.existingTaskChunkIds.add("chunk-1");

        job.runBatch(1, 200);

        assertTrue(store.createdTasks.isEmpty());
        assertEquals(List.of("chunk-1"), store.resetTasks);
        assertEquals(1, store.resetChunks.size());
    }

    @Test
    void backfillIsRejectedWhenRagIsDisabled() {
        properties.setEnabled(false);

        RagBackfillJob.RagBackfillResult result = job.runBatch(1, 200);

        assertFalse(result.enabled());
        assertEquals(0, result.processedDocuments());
    }

    @Test
    void runBatchesStopsAsSoonAsAPageIsNotFull() {
        documents.add(document("doc-1"));

        RagBackfillJob.RagBackfillRunResult result = job.runBatches(1, 200, 20);

        assertEquals(1, result.processedPages());
        assertEquals(1, result.processedDocuments());
        assertFalse(result.hasMore());
    }

    @Test
    void aFailingDocumentIsCountedButDoesNotAbortThePage() {
        documents.add(document("doc-1"));
        documents.add(document("doc-2"));
        chunks.add(chunk("chunk-1", "doc-1", RagEmbeddingStatus.CHUNK_PENDING_EMBEDDING));
        chunks.add(chunk("chunk-2", "doc-2", RagEmbeddingStatus.CHUNK_PENDING_EMBEDDING));
        failureDocumentId = "doc-1";

        RagBackfillJob.RagBackfillResult result = job.runBatch(1, 200);

        assertEquals(1, result.processedDocuments());
        assertEquals(1, result.failedDocuments());
    }

    private RagDocumentMapper documentMapper() {
        return (RagDocumentMapper) Proxy.newProxyInstance(
                RagDocumentMapper.class.getClassLoader(),
                new Class<?>[]{RagDocumentMapper.class},
                (proxy, method, args) -> {
                    if ("selectPage".equals(method.getName())) {
                        Page<RagDocument> page = new Page<>(1, 200);
                        page.setRecords(documents);
                        page.setTotal(documents.size());
                        return page;
                    }
                    return null;
                });
    }

    private RagChunkMapper chunkMapper() {
        return (RagChunkMapper) Proxy.newProxyInstance(
                RagChunkMapper.class.getClassLoader(),
                new Class<?>[]{RagChunkMapper.class},
                (proxy, method, args) -> {
                    if (!"selectList".equals(method.getName())) {
                        return null;
                    }
                    QueryWrapper<RagChunk> wrapper = (QueryWrapper<RagChunk>) args[0];
                    // 包装器在渲染 SQL 时才把参数绑进去，先渲染再取绑定值。
                    wrapper.getCustomSqlSegment();
                    List<Object> bound = new ArrayList<>(wrapper.getParamNameValuePairs().values());
                    String documentId = bound.isEmpty() ? null : String.valueOf(bound.get(0));
                    if (documentId != null && documentId.equals(failureDocumentId)) {
                        throw new IllegalStateException("chunk read failed for " + documentId);
                    }
                    List<RagChunk> selected = new ArrayList<>();
                    for (RagChunk chunk : chunks) {
                        if (documentId == null || documentId.equals(chunk.getDocumentId())) {
                            selected.add(chunk);
                        }
                    }
                    return selected;
                });
    }

    private static RagDocument document(String id) {
        RagDocument document = new RagDocument();
        document.setId(id);
        document.setSourceType("MANUAL");
        document.setStatus("READY");
        document.setTitle("文档 " + id);
        document.setSourceId("source-" + id);
        document.setAclScope("PUBLIC");
        document.setMetadataJson("{}");
        return document;
    }

    private static RagChunk chunk(String id, String documentId, String status) {
        RagChunk chunk = new RagChunk();
        chunk.setId(id);
        chunk.setDocumentId(documentId);
        chunk.setContent("罚款应当在十五日内缴纳。");
        chunk.setContentHash("hash-" + id);
        chunk.setChunkNo(0);
        chunk.setStatus(status);
        chunk.setUpdatedAt(LocalDateTime.now());
        return chunk;
    }

    private static final class FakeProvider implements RagEmbeddingProvider {

        @Override
        public String providerName() {
            return "ollama";
        }

        @Override
        public String modelName() {
            return "nomic-embed-text";
        }

        @Override
        public int dimensions() {
            return 768;
        }

        @Override
        public float[] embed(String text) {
            return new float[768];
        }
    }

    private static final class FakeStore implements RagEmbeddingTaskStore {

        private final List<String> createdTasks = new ArrayList<>();
        private final List<String> resetTasks = new ArrayList<>();
        private final List<String> resetChunks = new ArrayList<>();
        private final List<String> existingTaskChunkIds = new ArrayList<>();

        @Override
        public List<RagEmbeddingTask> selectPending(int limit) {
            return List.of();
        }

        @Override
        public boolean claim(RagEmbeddingTask task, String provider, String model) {
            return false;
        }

        @Override
        public RagEmbeddingTask reload(String taskId) {
            return null;
        }

        @Override
        public int reclaimStaleRunning(Duration staleAfter) {
            return 0;
        }

        @Override
        public RagChunk findChunk(String chunkId) {
            return null;
        }

        @Override
        public RagDocument findDocument(String documentId) {
            return null;
        }

        @Override
        public void markSucceeded(RagChunk chunk, RagEmbeddingTask task, String model, String embeddingHash) {
        }

        @Override
        public void markFailed(RagEmbeddingTask task, String message, int maxAttempts, Duration retryDelay) {
        }

        @Override
        public void poison(RagEmbeddingTask task, String message) {
        }

        @Override
        public List<RagChunk> selectChunksNeedingEmbedding(int limit) {
            return List.of();
        }

        @Override
        public List<RagChunk> selectChunks(int limit) {
            return List.of();
        }

        @Override
        public int resetChunk(RagChunk chunk, String model) {
            resetChunks.add(chunk.getId());
            chunk.setStatus(RagEmbeddingStatus.CHUNK_PENDING_EMBEDDING);
            return 1;
        }

        @Override
        public int resetTasks(String chunkId, String provider, String model) {
            if (!existingTaskChunkIds.contains(chunkId)) {
                return 0;
            }
            resetTasks.add(chunkId);
            return 1;
        }

        @Override
        public void createPendingTask(String chunkId, String provider, String model) {
            createdTasks.add(chunkId);
        }
    }
}
