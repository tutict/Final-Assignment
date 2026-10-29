package finalassignmentbackend.rag.embedding;

import finalassignmentbackend.rag.entity.RagChunk;
import finalassignmentbackend.rag.entity.RagDocument;
import finalassignmentbackend.rag.entity.RagEmbeddingTask;

import java.time.Duration;
import java.util.List;

/**
 * 嵌入队列的持久化边界。
 *
 * <p>工作器只关心「取任务、认领任务、改状态」这些意图，SQL 细节留给实现，
 * 这样任务状态机可以被独立验证。
 */
public interface RagEmbeddingTaskStore {

    /** 取待处理任务：状态是 PENDING 或 FAILED，且已经过了重试时间。 */
    List<RagEmbeddingTask> selectPending(int limit);

    /** 认领任务；返回 false 表示任务已被其它进程取走。 */
    boolean claim(RagEmbeddingTask task, String provider, String model);

    RagEmbeddingTask reload(String taskId);

    /** 把僵死在 RUNNING 的任务放回队列。 */
    int reclaimStaleRunning(Duration staleAfter);

    RagChunk findChunk(String chunkId);

    RagDocument findDocument(String documentId);

    /** 分块与任务同时置为成功。 */
    void markSucceeded(RagChunk chunk, RagEmbeddingTask task, String model, String embeddingHash);

    /** 失败重试；达到最大尝试次数后转为 POISONED。 */
    void markFailed(RagEmbeddingTask task, String message, int maxAttempts, Duration retryDelay);

    /** 分块或文档已不存在，任务无法重试，直接置为 POISONED。 */
    void poison(RagEmbeddingTask task, String message);

    /** 需要重新嵌入的分块。 */
    List<RagChunk> selectChunksNeedingEmbedding(int limit);

    int resetChunk(RagChunk chunk, String model);

    int resetTasks(String chunkId, String provider, String model);

    void createPendingTask(String chunkId, String provider, String model);
}
