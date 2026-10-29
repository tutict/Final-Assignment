package finalassignmentbackend.rag.embedding;

import finalassignmentbackend.rag.config.RagProperties;
import finalassignmentbackend.rag.elasticsearch.RagChunkSourceFactory;
import finalassignmentbackend.rag.elasticsearch.RagIndexManager;
import finalassignmentbackend.rag.entity.RagChunk;
import finalassignmentbackend.rag.entity.RagDocument;
import finalassignmentbackend.rag.entity.RagEmbeddingTask;
import jakarta.json.JsonObject;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.time.Duration;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

class RagEmbeddingWorkerTest {

    private RagProperties properties;
    private FakeStore store;
    private FakeProvider provider;
    private RecordingIndexManager indexManager;
    private RagEmbeddingWorker worker;

    @BeforeEach
    void setUp() {
        properties = new RagProperties();
        properties.setEmbeddingEnabled(true);
        properties.setEmbeddingMaxAttempts(2);
        properties.setEmbeddingRetryDelay(Duration.ofMinutes(1));
        properties.setEmbeddingRequestBudget(Duration.ofSeconds(20));
        store = new FakeStore();
        provider = new FakeProvider();
        indexManager = new RecordingIndexManager();
        worker = new RagEmbeddingWorker();
        worker.store = store;
        worker.provider = provider;
        worker.indexManager = indexManager;
        worker.sourceFactory = new RagChunkSourceFactory();
        worker.properties = properties;
    }

    @Test
    void successfulEmbeddingWritesChunkToIndexAndMarksTaskSucceeded() {
        RagEmbeddingTask task = pendingTask("task-1", "chunk-1");
        RagChunk chunk = chunk("chunk-1", "doc-1");
        RagDocument document = document("doc-1");
        store.tasks.add(task);
        store.chunks.put("chunk-1", chunk);
        store.documents.put("doc-1", document);

        RagEmbeddingWorker.EmbeddingBatchResult result = worker.processPendingBatch(10);

        assertEquals(1, result.selectedTasks());
        assertEquals(1, result.succeededTasks());
        assertEquals(0, result.failedTasks());
        assertEquals(List.of("chunk-1"), indexManager.indexed);
        assertEquals(RagEmbeddingStatus.CHUNK_EMBEDDED, chunk.getStatus());
        assertEquals("nomic-embed-text", chunk.getEmbeddingModel());
        assertNotNull(chunk.getEmbeddingHash());
        assertEquals(RagEmbeddingStatus.SUCCEEDED, store.statusOf("task-1"));
    }

    @Test
    void failedEmbeddingDoesNotTouchIndexAndKeepsTaskRetryable() {
        RagEmbeddingTask task = pendingTask("task-1", "chunk-1");
        store.tasks.add(task);
        store.chunks.put("chunk-1", chunk("chunk-1", "doc-1"));
        store.documents.put("doc-1", document("doc-1"));
        provider.failure = new RagEmbeddingException("Ollama embedding request failed with HTTP 500", 500);

        RagEmbeddingWorker.EmbeddingBatchResult result = worker.processPendingBatch(10);

        assertEquals(1, result.failedTasks());
        assertTrue(indexManager.indexed.isEmpty());
        assertEquals(RagEmbeddingStatus.FAILED, store.statusOf("task-1"));
        assertTrue(store.lastError.contains("HTTP 500"));
    }

    @Test
    void repeatedFailuresPoisonTheTask() {
        RagEmbeddingTask task = pendingTask("task-1", "chunk-1");
        task.setAttemptCount(2);
        store.tasks.add(task);
        store.chunks.put("chunk-1", chunk("chunk-1", "doc-1"));
        store.documents.put("doc-1", document("doc-1"));
        provider.failure = new RagEmbeddingException("dimension mismatch", 0);

        worker.processPendingBatch(10);

        assertEquals(RagEmbeddingStatus.POISONED, store.statusOf("task-1"));
        assertTrue(indexManager.indexed.isEmpty());
    }

    @Test
    void missingChunkPoisonsTheTaskInsteadOfFailing() {
        RagEmbeddingTask task = pendingTask("task-1", "chunk-missing");
        store.tasks.add(task);

        RagEmbeddingWorker.EmbeddingBatchResult result = worker.processPendingBatch(10);

        assertEquals(1, result.failedTasks());
        assertEquals(RagEmbeddingStatus.POISONED, store.statusOf("task-1"));
        assertTrue(store.lastError.contains("chunk does not exist"));
    }

    @Test
    void disabledEmbeddingIsReportedInsteadOfProcessing() {
        properties.setEmbeddingEnabled(false);
        store.tasks.add(pendingTask("task-1", "chunk-1"));

        RagEmbeddingWorker.EmbeddingBatchResult result = worker.processPendingBatch(10);

        assertEquals(0, result.selectedTasks());
        assertFalse(result.enabled());
        assertTrue(indexManager.indexed.isEmpty());
    }

    @Test
    void requeueResetsChunksAndCreatesMissingTask() {
        RagChunk chunk = chunk("chunk-1", "doc-1");
        chunk.setStatus(RagEmbeddingStatus.CHUNK_PENDING_EMBEDDING);
        store.chunks.put("chunk-1", chunk);

        RagEmbeddingWorker.RequeueResult result = worker.requeue(10);

        assertEquals(1, result.requeuedChunks());
        assertEquals(0, result.requeuedTasks());
        assertEquals(1, result.createdTasks());
        assertEquals(RagEmbeddingStatus.PENDING, store.statusOf("emb_" + chunk.getId()));
    }

    @Test
    void requeueAllAlsoRequeuesChunksThatWereAlreadyEmbedded() {
        RagChunk chunk = chunk("chunk-1", "doc-1");
        chunk.setStatus(RagEmbeddingStatus.CHUNK_EMBEDDED);
        store.chunks.put("chunk-1", chunk);

        RagEmbeddingWorker.RequeueResult result = worker.requeueAll(10);

        assertEquals(1, result.requeuedChunks());
        assertEquals(1, result.createdTasks());
        assertEquals(RagEmbeddingStatus.CHUNK_PENDING_EMBEDDING, chunk.getStatus());
        assertEquals(RagEmbeddingStatus.PENDING, store.statusOf("emb_chunk-1"));
    }

    private static RagEmbeddingTask pendingTask(String id, String chunkId) {
        RagEmbeddingTask task = new RagEmbeddingTask();
        task.setId(id);
        task.setChunkId(chunkId);
        task.setTaskKey(id);
        task.setProvider("ollama");
        task.setModel("nomic-embed-text");
        task.setStatus(RagEmbeddingStatus.PENDING);
        task.setAttemptCount(0);
        task.setCreatedAt(LocalDateTime.now());
        task.setUpdatedAt(LocalDateTime.now());
        return task;
    }

    private static RagChunk chunk(String id, String documentId) {
        RagChunk chunk = new RagChunk();
        chunk.setId(id);
        chunk.setDocumentId(documentId);
        chunk.setContent("违章处理流程");
        chunk.setContentHash("hash-" + id);
        chunk.setChunkNo(0);
        chunk.setStatus(RagEmbeddingStatus.CHUNK_PENDING_EMBEDDING);
        return chunk;
    }

    private static RagDocument document(String id) {
        RagDocument document = new RagDocument();
        document.setId(id);
        document.setSourceType("BUSINESS");
        document.setSourceTable("offense");
        document.setSourceId("source-" + id);
        document.setSourceVersion("v1");
        document.setTitle("文档 " + id);
        document.setAclScope("PUBLIC");
        document.setMetadataJson("{}");
        document.setStatus("READY");
        return document;
    }

    private static final class FakeProvider implements RagEmbeddingProvider {

        private RuntimeException failure;

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
            return 3;
        }

        @Override
        public float[] embed(String text) {
            if (failure != null) {
                throw failure;
            }
            return new float[]{1f, 0f, 0f};
        }
    }

    private static final class RecordingIndexManager extends RagIndexManager {

        private final List<String> indexed = new ArrayList<>();

        @Override
        public void indexChunk(String chunkId, JsonObject source) {
            indexed.add(chunkId);
        }
    }

    private static final class FakeStore implements RagEmbeddingTaskStore {

        private final List<RagEmbeddingTask> tasks = new ArrayList<>();
        private final Map<String, RagChunk> chunks = new LinkedHashMap<>();
        private final Map<String, RagDocument> documents = new LinkedHashMap<>();
        private final Map<String, String> statuses = new LinkedHashMap<>();
        private String lastError = "";

        @Override
        public List<RagEmbeddingTask> selectPending(int limit) {
            List<RagEmbeddingTask> pending = new ArrayList<>();
            for (RagEmbeddingTask task : tasks) {
                if (RagEmbeddingStatus.PENDING.equals(task.getStatus())
                        || RagEmbeddingStatus.FAILED.equals(task.getStatus())) {
                    pending.add(task);
                }
            }
            return pending.size() > limit ? pending.subList(0, limit) : pending;
        }

        @Override
        public boolean claim(RagEmbeddingTask task, String provider, String model) {
            if (!RagEmbeddingStatus.PENDING.equals(task.getStatus())
                    && !RagEmbeddingStatus.FAILED.equals(task.getStatus())) {
                return false;
            }
            task.setStatus(RagEmbeddingStatus.RUNNING);
            task.setAttemptCount((task.getAttemptCount() == null ? 0 : task.getAttemptCount()) + 1);
            statuses.put(task.getId(), RagEmbeddingStatus.RUNNING);
            return true;
        }

        @Override
        public RagEmbeddingTask reload(String taskId) {
            for (RagEmbeddingTask task : tasks) {
                if (task.getId().equals(taskId)) {
                    return task;
                }
            }
            return null;
        }

        @Override
        public int reclaimStaleRunning(Duration staleAfter) {
            return 0;
        }

        @Override
        public RagChunk findChunk(String chunkId) {
            return chunks.get(chunkId);
        }

        @Override
        public RagDocument findDocument(String documentId) {
            return documents.get(documentId);
        }

        @Override
        public void markSucceeded(RagChunk chunk, RagEmbeddingTask task, String model, String embeddingHash) {
            chunk.setStatus(RagEmbeddingStatus.CHUNK_EMBEDDED);
            chunk.setEmbeddingModel(model);
            chunk.setEmbeddingHash(embeddingHash);
            statuses.put(task.getId(), RagEmbeddingStatus.SUCCEEDED);
        }

        @Override
        public void markFailed(RagEmbeddingTask task, String message, int maxAttempts, Duration retryDelay) {
            int attempts = task.getAttemptCount() == null ? 0 : task.getAttemptCount();
            statuses.put(task.getId(), attempts >= Math.max(1, maxAttempts)
                    ? RagEmbeddingStatus.POISONED
                    : RagEmbeddingStatus.FAILED);
            lastError = message == null ? "" : message;
        }

        @Override
        public void poison(RagEmbeddingTask task, String message) {
            statuses.put(task.getId(), RagEmbeddingStatus.POISONED);
            lastError = message == null ? "" : message;
        }

        @Override
        public List<RagChunk> selectChunksNeedingEmbedding(int limit) {
            List<RagChunk> selected = new ArrayList<>();
            for (RagChunk chunk : chunks.values()) {
                if (!RagEmbeddingStatus.CHUNK_EMBEDDED.equals(chunk.getStatus())) {
                    selected.add(chunk);
                }
            }
            return selected.size() > limit ? selected.subList(0, limit) : selected;
        }

        @Override
        public List<RagChunk> selectChunks(int limit) {
            List<RagChunk> selected = new ArrayList<>(chunks.values());
            return selected.size() > limit ? selected.subList(0, limit) : selected;
        }

        @Override
        public int resetChunk(RagChunk chunk, String model) {
            chunk.setStatus(RagEmbeddingStatus.CHUNK_PENDING_EMBEDDING);
            return 1;
        }

        @Override
        public int resetTasks(String chunkId, String provider, String model) {
            int updated = 0;
            for (RagEmbeddingTask task : tasks) {
                if (chunkId.equals(task.getChunkId())) {
                    task.setStatus(RagEmbeddingStatus.PENDING);
                    updated++;
                }
            }
            return updated;
        }

        @Override
        public void createPendingTask(String chunkId, String provider, String model) {
            RagEmbeddingTask task = pendingTask("emb_" + chunkId, chunkId);
            tasks.add(task);
            statuses.put(task.getId(), RagEmbeddingStatus.PENDING);
        }

        private String statusOf(String taskId) {
            return statuses.get(taskId);
        }
    }
}
