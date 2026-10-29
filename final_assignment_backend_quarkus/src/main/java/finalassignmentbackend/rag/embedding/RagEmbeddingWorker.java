package finalassignmentbackend.rag.embedding;

import finalassignmentbackend.rag.config.RagProperties;
import finalassignmentbackend.rag.elasticsearch.RagChunkSourceFactory;
import finalassignmentbackend.rag.elasticsearch.RagIndexManager;
import finalassignmentbackend.rag.entity.RagChunk;
import finalassignmentbackend.rag.entity.RagDocument;
import finalassignmentbackend.rag.entity.RagEmbeddingTask;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.json.JsonObject;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.time.Duration;
import java.util.HexFormat;
import java.util.List;
import java.util.concurrent.atomic.AtomicBoolean;

/**
 * 嵌入任务工作器：把待嵌入的分块变成 ES 里的向量文档。
 *
 * <p>顺序是「先写 ES，再标记成功」：ES 写成功但数据库标记失败时，分块状态仍不是 EMBEDDED，
 * 检索侧会把它过滤掉，不会出现「索引里有、库里说没有」的脏召回。
 */
@ApplicationScoped
public class RagEmbeddingWorker {

    /** RUNNING 超过这个时长就认为上一次执行被中断，重新排队。 */
    private static final Duration STALE_TASK_AFTER = Duration.ofMinutes(10);

    private final AtomicBoolean running = new AtomicBoolean(false);

    @Inject RagEmbeddingTaskStore store;
    @Inject RagEmbeddingProvider provider;
    @Inject RagIndexManager indexManager;
    @Inject RagChunkSourceFactory sourceFactory;
    @Inject RagProperties properties;

    public record EmbeddingBatchResult(int selectedTasks, int succeededTasks, int failedTasks,
                                       boolean enabled, boolean alreadyRunning, boolean hasMore) {
    }

    public record RequeueResult(int requeuedChunks, int requeuedTasks, int createdTasks) {
    }

    public EmbeddingBatchResult processPendingBatch(int requestedLimit) {
        boolean enabled = properties.isEnabled() && properties.isEmbeddingEnabled();
        if (!enabled) {
            return new EmbeddingBatchResult(0, 0, 0, false, false, false);
        }
        if (!running.compareAndSet(false, true)) {
            return new EmbeddingBatchResult(0, 0, 0, true, true, false);
        }
        try {
            int limit = Math.min(Math.max(1, requestedLimit), 500);
            store.reclaimStaleRunning(STALE_TASK_AFTER);
            List<RagEmbeddingTask> tasks = store.selectPending(limit);
            long deadline = System.nanoTime() + budgetNanos();
            int succeeded = 0;
            int failed = 0;
            int started = 0;
            for (RagEmbeddingTask candidate : tasks) {
                // 预算耗尽后不再开启新任务，剩余的留给下一次调用，避免单次请求超时。
                if (started > 0 && System.nanoTime() > deadline) {
                    break;
                }
                started++;
                if (processTask(candidate)) {
                    succeeded++;
                } else {
                    failed++;
                }
            }
            boolean hasMore = !store.selectPending(1).isEmpty();
            return new EmbeddingBatchResult(tasks.size(), succeeded, failed, true, false, hasMore);
        } finally {
            running.set(false);
        }
    }

    /** 把失败、中毒或尚未嵌入的分块重新排队。 */
    public RequeueResult requeue(int requestedLimit) {
        int limit = Math.min(Math.max(1, requestedLimit), 1000);
        List<RagChunk> chunks = store.selectChunksNeedingEmbedding(limit);
        int requeuedChunks = 0;
        int requeuedTasks = 0;
        int createdTasks = 0;
        for (RagChunk chunk : chunks) {
            requeuedChunks += store.resetChunk(chunk, provider.modelName());
            int updated = store.resetTasks(chunk.getId(), provider.providerName(), provider.modelName());
            if (updated == 0) {
                store.createPendingTask(chunk.getId(), provider.providerName(), provider.modelName());
                createdTasks++;
            } else {
                requeuedTasks += updated;
            }
        }
        return new RequeueResult(requeuedChunks, requeuedTasks, createdTasks);
    }

    private boolean processTask(RagEmbeddingTask candidate) {
        if (!store.claim(candidate, provider.providerName(), provider.modelName())) {
            return false;
        }
        RagEmbeddingTask task = store.reload(candidate.getId());
        if (task == null) {
            return false;
        }
        RagChunk chunk = store.findChunk(task.getChunkId());
        if (chunk == null) {
            store.poison(task, "RAG chunk does not exist: " + task.getChunkId());
            return false;
        }
        RagDocument document = store.findDocument(chunk.getDocumentId());
        if (document == null) {
            store.poison(task, "RAG document does not exist: " + chunk.getDocumentId());
            return false;
        }
        try {
            float[] vector = provider.embed(chunk.getContent());
            JsonObject source = sourceFactory.build(document, chunk, vector,
                    provider.providerName(), provider.modelName());
            indexManager.indexChunk(chunk.getId(), source);
            store.markSucceeded(chunk, task, provider.modelName(),
                    embeddingHash(provider.providerName(), provider.modelName(), chunk.getContentHash(), vector));
            return true;
        } catch (RuntimeException error) {
            store.markFailed(task, error.getMessage(), properties.getEmbeddingMaxAttempts(),
                    properties.getEmbeddingRetryDelay());
            return false;
        }
    }

    /** 嵌入指纹：模型与内容变化都会改变它，用于判断向量是否已经过期。 */
    static String embeddingHash(String provider, String model, String contentHash, float[] vector) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            updateDigest(digest, provider);
            updateDigest(digest, model);
            updateDigest(digest, contentHash);
            for (float value : vector) {
                digest.update(Float.toString(value).getBytes(StandardCharsets.UTF_8));
            }
            return HexFormat.of().formatHex(digest.digest());
        } catch (NoSuchAlgorithmException error) {
            throw new IllegalStateException("SHA-256 is not available", error);
        }
    }

    private static void updateDigest(MessageDigest digest, String value) {
        digest.update((value == null ? "" : value).getBytes(StandardCharsets.UTF_8));
        digest.update((byte) 0x1f);
    }

    private long budgetNanos() {
        Duration budget = properties.getEmbeddingRequestBudget();
        if (budget == null || budget.isZero() || budget.isNegative()) {
            budget = Duration.ofSeconds(20);
        }
        return budget.toNanos();
    }
}
