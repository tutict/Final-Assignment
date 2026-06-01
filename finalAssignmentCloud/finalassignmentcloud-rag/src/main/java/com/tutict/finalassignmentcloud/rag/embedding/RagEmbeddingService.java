package com.tutict.finalassignmentcloud.rag.embedding;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.tutict.finalassignmentcloud.rag.ai.retrieval.EmbeddingProvider;
import com.tutict.finalassignmentcloud.rag.config.RagProperties;
import com.tutict.finalassignmentcloud.rag.entity.RagChunk;
import com.tutict.finalassignmentcloud.rag.entity.RagDocument;
import com.tutict.finalassignmentcloud.rag.entity.RagEmbeddingTask;
import com.tutict.finalassignmentcloud.rag.mapper.RagChunkMapper;
import com.tutict.finalassignmentcloud.rag.mapper.RagDocumentMapper;
import com.tutict.finalassignmentcloud.rag.mapper.RagEmbeddingTaskMapper;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.time.LocalDateTime;
import java.util.HexFormat;
import java.util.List;
import java.util.concurrent.atomic.AtomicBoolean;

@Service
@ConditionalOnProperty(prefix = "rag.embedding", name = "enabled", havingValue = "true")
public class RagEmbeddingService {

    private static final String STATUS_PENDING = "PENDING";
    private static final String STATUS_RUNNING = "RUNNING";
    private static final String STATUS_SUCCEEDED = "SUCCEEDED";
    private static final String STATUS_FAILED = "FAILED";
    private static final String STATUS_POISONED = "POISONED";

    private final RagEmbeddingTaskMapper taskMapper;
    private final RagChunkMapper chunkMapper;
    private final RagDocumentMapper documentMapper;
    private final EmbeddingProvider embeddingProvider;
    private final RagChunkVectorIndexService vectorIndexService;
    private final RagProperties properties;
    private final AtomicBoolean running = new AtomicBoolean(false);

    public RagEmbeddingService(
            RagEmbeddingTaskMapper taskMapper,
            RagChunkMapper chunkMapper,
            RagDocumentMapper documentMapper,
            EmbeddingProvider embeddingProvider,
            RagChunkVectorIndexService vectorIndexService,
            RagProperties properties
    ) {
        this.taskMapper = taskMapper;
        this.chunkMapper = chunkMapper;
        this.documentMapper = documentMapper;
        this.embeddingProvider = embeddingProvider;
        this.vectorIndexService = vectorIndexService;
        this.properties = properties;
    }

    @Scheduled(fixedDelayString = "${rag.embedding.poll-interval-ms:30000}")
    public void scheduledProcessPendingBatch() {
        processPendingBatch(properties.getEmbedding().getBatchSize());
    }

    public RagEmbeddingBatchResult processPendingBatch(int requestedLimit) {
        if (!properties.isEnabled() || !properties.getEmbedding().isEnabled()) {
            return new RagEmbeddingBatchResult(0, 0, 0, true, false);
        }
        if (!running.compareAndSet(false, true)) {
            return new RagEmbeddingBatchResult(0, 0, 0, false, true);
        }
        try {
            List<RagEmbeddingTask> tasks = selectPendingTasks(requestedLimit);
            int succeeded = 0;
            int failed = 0;
            for (RagEmbeddingTask task : tasks) {
                if (processTask(task)) {
                    succeeded++;
                } else {
                    failed++;
                }
            }
            return new RagEmbeddingBatchResult(tasks.size(), succeeded, failed, true, false);
        } finally {
            running.set(false);
        }
    }

    private List<RagEmbeddingTask> selectPendingTasks(int requestedLimit) {
        int limit = Math.min(Math.max(1, requestedLimit), 500);
        LocalDateTime now = LocalDateTime.now();
        return taskMapper.selectList(new QueryWrapper<RagEmbeddingTask>()
                .in("status", List.of(STATUS_PENDING, STATUS_FAILED))
                .and(wrapper -> wrapper.isNull("next_retry_at").or().le("next_retry_at", now))
                .orderByAsc("created_at")
                .last("LIMIT " + limit));
    }

    private boolean processTask(RagEmbeddingTask task) {
        RagEmbeddingTask currentTask = taskMapper.selectById(task.getId());
        if (currentTask == null || !isRunnable(currentTask)) {
            return false;
        }
        markRunning(currentTask);
        try {
            RagChunk chunk = chunkMapper.selectById(currentTask.getChunkId());
            if (chunk == null) {
                poison(currentTask, "RAG chunk does not exist: " + currentTask.getChunkId());
                return false;
            }
            RagDocument document = documentMapper.selectById(chunk.getDocumentId());
            if (document == null) {
                poison(currentTask, "RAG document does not exist: " + chunk.getDocumentId());
                return false;
            }
            float[] vector = embeddingProvider.embed(chunk.getContent());
            vectorIndexService.index(document, chunk, vector, embeddingProvider.providerName(), embeddingProvider.modelName());
            markSucceeded(currentTask, chunk, vector);
            return true;
        } catch (RuntimeException error) {
            markFailed(currentTask, error);
            return false;
        }
    }

    private boolean isRunnable(RagEmbeddingTask task) {
        if (!STATUS_PENDING.equals(task.getStatus()) && !STATUS_FAILED.equals(task.getStatus())) {
            return false;
        }
        LocalDateTime nextRetryAt = task.getNextRetryAt();
        return nextRetryAt == null || !nextRetryAt.isAfter(LocalDateTime.now());
    }

    private void markRunning(RagEmbeddingTask task) {
        task.setStatus(STATUS_RUNNING);
        task.setProvider(embeddingProvider.providerName());
        task.setModel(embeddingProvider.modelName());
        task.setAttemptCount(safeAttemptCount(task) + 1);
        task.setNextRetryAt(null);
        task.setLastError(null);
        task.setUpdatedAt(LocalDateTime.now());
        taskMapper.updateById(task);
    }

    private void markSucceeded(RagEmbeddingTask task, RagChunk chunk, float[] vector) {
        LocalDateTime now = LocalDateTime.now();
        chunk.setStatus("EMBEDDED");
        chunk.setEmbeddingModel(embeddingProvider.modelName());
        chunk.setEmbeddingHash(embeddingHash(chunk, vector));
        chunk.setUpdatedAt(now);
        chunkMapper.updateById(chunk);

        task.setStatus(STATUS_SUCCEEDED);
        task.setLastError(null);
        task.setNextRetryAt(null);
        task.setUpdatedAt(now);
        taskMapper.updateById(task);
    }

    private void markFailed(RagEmbeddingTask task, RuntimeException error) {
        LocalDateTime now = LocalDateTime.now();
        int maxAttempts = Math.max(1, properties.getEmbedding().getMaxAttempts());
        task.setStatus(safeAttemptCount(task) >= maxAttempts ? STATUS_POISONED : STATUS_FAILED);
        task.setLastError(clip(error.getMessage()));
        task.setNextRetryAt(STATUS_FAILED.equals(task.getStatus())
                ? now.plus(properties.getEmbedding().getRetryDelay())
                : null);
        task.setUpdatedAt(now);
        taskMapper.updateById(task);
    }

    private void poison(RagEmbeddingTask task, String message) {
        task.setStatus(STATUS_POISONED);
        task.setLastError(clip(message));
        task.setNextRetryAt(null);
        task.setUpdatedAt(LocalDateTime.now());
        taskMapper.updateById(task);
    }

    private String embeddingHash(RagChunk chunk, float[] vector) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            updateDigest(digest, embeddingProvider.providerName());
            updateDigest(digest, embeddingProvider.modelName());
            updateDigest(digest, chunk.getContentHash());
            for (float value : vector) {
                updateDigest(digest, Float.toString(value));
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

    private static int safeAttemptCount(RagEmbeddingTask task) {
        return task.getAttemptCount() == null ? 0 : task.getAttemptCount();
    }

    private static String clip(String message) {
        if (message == null || message.isBlank()) {
            return "unknown embedding error";
        }
        return message.length() <= 2000 ? message : message.substring(0, 2000);
    }

    public record RagEmbeddingBatchResult(
            int selectedTasks,
            int succeededTasks,
            int failedTasks,
            boolean enabled,
            boolean alreadyRunning
    ) {
    }
}

