package com.tutict.finalassignmentbackend.rag.indexing;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.core.conditions.update.UpdateWrapper;
import com.tutict.finalassignmentbackend.ai.rag.config.RagChunkIndexMapping;
import com.tutict.finalassignmentbackend.rag.config.RagProperties;
import com.tutict.finalassignmentbackend.rag.entity.RagChunk;
import com.tutict.finalassignmentbackend.rag.entity.RagEmbeddingTask;
import com.tutict.finalassignmentbackend.rag.mapper.RagChunkMapper;
import com.tutict.finalassignmentbackend.rag.mapper.RagEmbeddingTaskMapper;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.data.elasticsearch.core.ElasticsearchOperations;
import org.springframework.data.elasticsearch.core.IndexOperations;
import org.springframework.data.elasticsearch.core.document.Document;
import org.springframework.data.elasticsearch.core.index.AliasAction;
import org.springframework.data.elasticsearch.core.index.AliasActionParameters;
import org.springframework.data.elasticsearch.core.index.AliasActions;
import org.springframework.data.elasticsearch.core.mapping.IndexCoordinates;
import org.springframework.stereotype.Service;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.HexFormat;
import java.util.List;
import java.util.Map;

@Service
@ConditionalOnProperty(prefix = "rag", name = "enabled", havingValue = "true")
public class RagIndexMaintenanceService {

    private static final String STATUS_PENDING = "PENDING";
    private static final String STATUS_PENDING_EMBEDDING = "PENDING_EMBEDDING";

    private final ObjectProvider<ElasticsearchOperations> operationsProvider;
    private final RagChunkIndexMapping mapping;
    private final RagChunkMapper chunkMapper;
    private final RagEmbeddingTaskMapper taskMapper;
    private final RagProperties properties;

    public RagIndexMaintenanceService(
            ObjectProvider<ElasticsearchOperations> operationsProvider,
            RagChunkIndexMapping mapping,
            RagChunkMapper chunkMapper,
            RagEmbeddingTaskMapper taskMapper,
            RagProperties properties
    ) {
        this.operationsProvider = operationsProvider;
        this.mapping = mapping;
        this.chunkMapper = chunkMapper;
        this.taskMapper = taskMapper;
        this.properties = properties;
    }

    public RagIndexMigrationResult migrateToNewIndex(
            String requestedIndexName,
            boolean requeueExistingChunks,
            int requeueLimit
    ) {
        ElasticsearchOperations operations = operationsProvider.getIfAvailable();
        if (operations == null) {
            return new RagIndexMigrationResult(
                    false,
                    false,
                    false,
                    normalizeIndexName(requestedIndexName),
                    mapping.aliasName(),
                    0,
                    0,
                    0,
                    "ElasticsearchOperations is not available"
            );
        }

        String targetIndexName = normalizeIndexName(requestedIndexName);
        IndexOperations targetIndex = operations.indexOps(IndexCoordinates.of(targetIndexName));
        boolean created = false;
        if (!targetIndex.exists()) {
            targetIndex.create(mapping.settings(), Document.from(mapping.mapping()));
            created = true;
        }
        boolean aliasSwitched = switchWriteAlias(targetIndex, targetIndexName);
        RequeueResult requeueResult = requeueExistingChunks
                ? requeueEmbeddingTasks(requeueLimit)
                : new RequeueResult(0, 0, 0);

        return new RagIndexMigrationResult(
                true,
                created,
                aliasSwitched,
                targetIndexName,
                mapping.aliasName(),
                requeueResult.requeuedChunks(),
                requeueResult.requeuedTasks(),
                requeueResult.createdTasks(),
                ""
        );
    }

    public RequeueResult requeueEmbeddingTasks(int requestedLimit) {
        int limit = normalizeLimit(requestedLimit);
        List<RagChunk> chunks = chunkMapper.selectList(new QueryWrapper<RagChunk>()
                .orderByAsc("updated_at")
                .last("LIMIT " + limit));
        LocalDateTime now = LocalDateTime.now();
        int requeuedChunks = 0;
        int requeuedTasks = 0;
        int createdTasks = 0;
        for (RagChunk chunk : chunks) {
            requeuedChunks += resetChunk(chunk.getId(), now);
            int updatedTasks = resetExistingTasks(chunk.getId(), now);
            if (updatedTasks == 0) {
                createPendingTask(chunk.getId(), now);
                createdTasks++;
            } else {
                requeuedTasks += updatedTasks;
            }
        }
        return new RequeueResult(requeuedChunks, requeuedTasks, createdTasks);
    }

    private boolean switchWriteAlias(IndexOperations targetIndex, String targetIndexName) {
        Map<String, ?> existingAliases = targetIndex.getAliases(mapping.aliasName());
        List<AliasAction> actions = new ArrayList<>();
        for (String existingIndexName : existingAliases.keySet()) {
            actions.add(new AliasAction.Remove(AliasActionParameters.builder()
                    .withIndices(existingIndexName)
                    .withAliases(mapping.aliasName())
                    .build()));
        }
        actions.add(new AliasAction.Add(AliasActionParameters.builder()
                .withIndices(targetIndexName)
                .withAliases(mapping.aliasName())
                .withIsWriteIndex(true)
                .build()));
        return targetIndex.alias(new AliasActions(actions.toArray(new AliasAction[0])));
    }

    private int resetChunk(String chunkId, LocalDateTime now) {
        return chunkMapper.update(null, new UpdateWrapper<RagChunk>()
                .eq("id", chunkId)
                .set("status", STATUS_PENDING_EMBEDDING)
                .set("embedding_model", properties.getEmbedding().getModel())
                .set("embedding_hash", null)
                .set("updated_at", now));
    }

    private int resetExistingTasks(String chunkId, LocalDateTime now) {
        return taskMapper.update(null, new UpdateWrapper<RagEmbeddingTask>()
                .eq("chunk_id", chunkId)
                .set("provider", provider())
                .set("model", model())
                .set("status", STATUS_PENDING)
                .set("attempt_count", 0)
                .set("next_retry_at", null)
                .set("last_error", null)
                .set("updated_at", now));
    }

    private void createPendingTask(String chunkId, LocalDateTime now) {
        String taskKey = stableId("emb", chunkId, provider(), model());
        RagEmbeddingTask task = new RagEmbeddingTask();
        task.setId(taskKey);
        task.setChunkId(chunkId);
        task.setTaskKey(taskKey);
        task.setProvider(provider());
        task.setModel(model());
        task.setStatus(STATUS_PENDING);
        task.setAttemptCount(0);
        task.setCreatedAt(now);
        task.setUpdatedAt(now);
        taskMapper.insert(task);
    }

    private String normalizeIndexName(String requestedIndexName) {
        if (requestedIndexName != null && !requestedIndexName.isBlank()) {
            return requestedIndexName.trim();
        }
        return mapping.indexName() + "_" + System.currentTimeMillis();
    }

    private static int normalizeLimit(int requestedLimit) {
        return Math.min(Math.max(requestedLimit, 1), 5000);
    }

    private String provider() {
        return defaultIfBlank(properties.getEmbedding().getProvider(), "unassigned");
    }

    private String model() {
        return defaultIfBlank(properties.getEmbedding().getModel(), "unassigned");
    }

    private static String defaultIfBlank(String value, String fallback) {
        return value == null || value.isBlank() ? fallback : value.trim();
    }

    private static String stableId(String prefix, String... parts) {
        return prefix + "_" + sha256Hex(String.join("\u001F", parts)).substring(0, 32);
    }

    private static String sha256Hex(String value) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            return HexFormat.of().formatHex(digest.digest(value.getBytes(StandardCharsets.UTF_8)));
        } catch (NoSuchAlgorithmException error) {
            throw new IllegalStateException("SHA-256 is not available", error);
        }
    }

    public record RagIndexMigrationResult(
            boolean enabled,
            boolean createdIndex,
            boolean aliasSwitched,
            String targetIndexName,
            String aliasName,
            int requeuedChunks,
            int requeuedTasks,
            int createdTasks,
            String message
    ) {
    }

    public record RequeueResult(
            int requeuedChunks,
            int requeuedTasks,
            int createdTasks
    ) {
    }
}
