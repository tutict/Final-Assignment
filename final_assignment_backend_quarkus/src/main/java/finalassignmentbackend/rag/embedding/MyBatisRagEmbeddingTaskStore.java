package finalassignmentbackend.rag.embedding;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.core.conditions.update.UpdateWrapper;
import finalassignmentbackend.mapper.RagChunkMapper;
import finalassignmentbackend.mapper.RagDocumentMapper;
import finalassignmentbackend.mapper.RagEmbeddingTaskMapper;
import finalassignmentbackend.rag.RagHashSupport;
import finalassignmentbackend.rag.entity.RagChunk;
import finalassignmentbackend.rag.entity.RagDocument;
import finalassignmentbackend.rag.entity.RagEmbeddingTask;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.transaction.Transactional;

import java.time.Duration;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;

/**
 * 嵌入队列的 MySQL 实现。
 *
 * <p>认领任务使用带状态条件的 UPDATE：只有把状态从 PENDING/FAILED 改成 RUNNING 成功的那一方
 * 才真正获得这个任务，多个后端同时轮询同一张表时不会重复处理同一条任务。
 */
@ApplicationScoped
public class MyBatisRagEmbeddingTaskStore implements RagEmbeddingTaskStore {

    @Inject RagEmbeddingTaskMapper taskMapper;
    @Inject RagChunkMapper chunkMapper;
    @Inject RagDocumentMapper documentMapper;

    @Override
    public List<RagEmbeddingTask> selectPending(int limit) {
        LocalDateTime now = LocalDateTime.now();
        return taskMapper.selectList(new QueryWrapper<RagEmbeddingTask>()
                .in("status", List.of(RagEmbeddingStatus.PENDING, RagEmbeddingStatus.FAILED))
                .and(wrapper -> wrapper.isNull("next_retry_at").or().le("next_retry_at", now))
                .orderByAsc("created_at")
                .last("LIMIT " + limit));
    }

    @Override
    public boolean claim(RagEmbeddingTask task, String provider, String model) {
        if (task == null || task.getId() == null) {
            return false;
        }
        UpdateWrapper<RagEmbeddingTask> wrapper = new UpdateWrapper<>();
        wrapper.set("status", RagEmbeddingStatus.RUNNING)
                .set("provider", provider)
                .set("model", model)
                .set("updated_at", LocalDateTime.now())
                .setSql("attempt_count = COALESCE(attempt_count, 0) + 1")
                .setSql("next_retry_at = null")
                .setSql("last_error = null")
                .eq("id", task.getId())
                .in("status", List.of(RagEmbeddingStatus.PENDING, RagEmbeddingStatus.FAILED));
        return taskMapper.update(null, wrapper) > 0;
    }

    @Override
    public RagEmbeddingTask reload(String taskId) {
        return taskId == null ? null : taskMapper.selectById(taskId);
    }

    @Override
    public int reclaimStaleRunning(Duration staleAfter) {
        LocalDateTime threshold = LocalDateTime.now().minus(staleAfter);
        UpdateWrapper<RagEmbeddingTask> wrapper = new UpdateWrapper<>();
        wrapper.set("status", RagEmbeddingStatus.FAILED)
                .set("last_error", "Embedding task was interrupted and has been requeued")
                .set("updated_at", LocalDateTime.now())
                .setSql("next_retry_at = null")
                .eq("status", RagEmbeddingStatus.RUNNING)
                .lt("updated_at", threshold);
        return taskMapper.update(null, wrapper);
    }

    @Override
    public RagChunk findChunk(String chunkId) {
        return chunkId == null ? null : chunkMapper.selectById(chunkId);
    }

    @Override
    public RagDocument findDocument(String documentId) {
        return documentId == null ? null : documentMapper.selectById(documentId);
    }

    @Override
    @Transactional
    public void markSucceeded(RagChunk chunk, RagEmbeddingTask task, String model, String embeddingHash) {
        LocalDateTime now = LocalDateTime.now();
        chunk.setStatus(RagEmbeddingStatus.CHUNK_EMBEDDED);
        chunk.setEmbeddingModel(model);
        chunk.setEmbeddingHash(embeddingHash);
        chunk.setUpdatedAt(now);
        chunkMapper.updateById(chunk);

        UpdateWrapper<RagEmbeddingTask> wrapper = new UpdateWrapper<>();
        wrapper.set("status", RagEmbeddingStatus.SUCCEEDED)
                .set("updated_at", now)
                .setSql("next_retry_at = null")
                .setSql("last_error = null")
                .eq("id", task.getId());
        taskMapper.update(null, wrapper);
    }

    @Override
    public void markFailed(RagEmbeddingTask task, String message, int maxAttempts, Duration retryDelay) {
        LocalDateTime now = LocalDateTime.now();
        int attempts = task.getAttemptCount() == null ? 0 : task.getAttemptCount();
        boolean poisoned = attempts >= Math.max(1, maxAttempts);
        UpdateWrapper<RagEmbeddingTask> wrapper = new UpdateWrapper<>();
        wrapper.set("status", poisoned ? RagEmbeddingStatus.POISONED : RagEmbeddingStatus.FAILED)
                .set("last_error", clip(message))
                .set("updated_at", now);
        if (poisoned) {
            wrapper.setSql("next_retry_at = null");
        } else {
            wrapper.set("next_retry_at", now.plus(retryDelay));
        }
        wrapper.eq("id", task.getId());
        taskMapper.update(null, wrapper);
    }

    @Override
    public void poison(RagEmbeddingTask task, String message) {
        UpdateWrapper<RagEmbeddingTask> wrapper = new UpdateWrapper<>();
        wrapper.set("status", RagEmbeddingStatus.POISONED)
                .set("last_error", clip(message))
                .set("updated_at", LocalDateTime.now())
                .setSql("next_retry_at = null")
                .eq("id", task.getId());
        taskMapper.update(null, wrapper);
    }

    @Override
    public List<RagChunk> selectChunksNeedingEmbedding(int limit) {
        Set<String> chunkIds = new LinkedHashSet<>();
        List<RagChunk> chunks = new ArrayList<>(chunkMapper.selectList(new QueryWrapper<RagChunk>()
                .ne("status", RagEmbeddingStatus.CHUNK_EMBEDDED)
                .orderByAsc("updated_at")
                .last("LIMIT " + limit)));
        for (RagChunk chunk : chunks) {
            chunkIds.add(chunk.getId());
        }
        if (chunkIds.size() < limit) {
            List<RagEmbeddingTask> broken = taskMapper.selectList(new QueryWrapper<RagEmbeddingTask>()
                    .in("status", List.of(RagEmbeddingStatus.FAILED, RagEmbeddingStatus.POISONED)));
            for (RagEmbeddingTask task : broken) {
                if (task.getChunkId() == null || chunkIds.contains(task.getChunkId())) {
                    continue;
                }
                RagChunk chunk = chunkMapper.selectById(task.getChunkId());
                if (chunk != null) {
                    chunkIds.add(chunk.getId());
                    chunks.add(chunk);
                }
            }
        }
        return chunks;
    }

    @Override
    public int resetChunk(RagChunk chunk, String model) {
        UpdateWrapper<RagChunk> wrapper = new UpdateWrapper<>();
        wrapper.set("status", RagEmbeddingStatus.CHUNK_PENDING_EMBEDDING)
                .set("embedding_model", model)
                .set("updated_at", LocalDateTime.now())
                .setSql("embedding_hash = null")
                .eq("id", chunk.getId());
        return chunkMapper.update(null, wrapper);
    }

    @Override
    public int resetTasks(String chunkId, String provider, String model) {
        UpdateWrapper<RagEmbeddingTask> wrapper = new UpdateWrapper<>();
        wrapper.set("provider", provider)
                .set("model", model)
                .set("status", RagEmbeddingStatus.PENDING)
                .set("attempt_count", 0)
                .set("updated_at", LocalDateTime.now())
                .setSql("next_retry_at = null")
                .setSql("last_error = null")
                .eq("chunk_id", chunkId);
        return taskMapper.update(null, wrapper);
    }

    @Override
    public void createPendingTask(String chunkId, String provider, String model) {
        LocalDateTime now = LocalDateTime.now();
        String taskKey = RagHashSupport.stableId("emb", chunkId, provider, model);
        RagEmbeddingTask task = new RagEmbeddingTask();
        task.setId(taskKey);
        task.setChunkId(chunkId);
        task.setTaskKey(taskKey);
        task.setProvider(provider);
        task.setModel(model);
        task.setStatus(RagEmbeddingStatus.PENDING);
        task.setAttemptCount(0);
        task.setCreatedAt(now);
        task.setUpdatedAt(now);
        taskMapper.insert(task);
    }

    private static String clip(String message) {
        if (message == null) {
            return "";
        }
        return message.length() <= 500 ? message : message.substring(0, 500);
    }
}
