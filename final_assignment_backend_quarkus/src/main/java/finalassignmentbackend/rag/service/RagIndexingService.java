package finalassignmentbackend.rag.service;

import finalassignmentbackend.mapper.RagChunkMapper;
import finalassignmentbackend.mapper.RagDocumentMapper;
import finalassignmentbackend.mapper.RagEmbeddingTaskMapper;
import finalassignmentbackend.offense.governance.AfterCommitBoundary;
import finalassignmentbackend.rag.RagHashSupport;
import finalassignmentbackend.rag.chunk.ChineseTextChunker;
import finalassignmentbackend.rag.chunk.Chunker;
import finalassignmentbackend.rag.config.RagProperties;
import finalassignmentbackend.rag.dto.RagSourceDocument;
import finalassignmentbackend.rag.elasticsearch.RagIndexManager;
import finalassignmentbackend.rag.embedding.RagEmbeddingStatus;
import finalassignmentbackend.rag.entity.RagChunk;
import finalassignmentbackend.rag.entity.RagDocument;
import finalassignmentbackend.rag.entity.RagEmbeddingTask;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.transaction.Transactional;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Locale;
import java.util.Set;
import java.util.logging.Level;
import java.util.logging.Logger;
import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.core.conditions.update.UpdateWrapper;

@ApplicationScoped
public class RagIndexingService {

    private static final Logger LOG = Logger.getLogger(RagIndexingService.class.getName());

    private final RagDocumentService documentService;
    private final RagChunkService chunkService;
    private final RagEmbeddingTaskService embeddingTaskService;
    private final Chunker chunker;
    private final RagIndexManager indexManager;

    public RagIndexingService(
            RagDocumentService documentService,
            RagChunkService chunkService,
            RagEmbeddingTaskService embeddingTaskService,
            Chunker chunker,
            RagIndexManager indexManager
    ) {
        this.documentService = documentService;
        this.chunkService = chunkService;
        this.embeddingTaskService = embeddingTaskService;
        this.chunker = chunker;
        this.indexManager = indexManager;
    }

    @Transactional
    public RagIndexingResult index(RagSourceDocument sourceDocument) {
        RagDocumentService.DocumentUpsert upsert = documentService.upsert(sourceDocument);
        RagDocument document = upsert.document();
        List<RagChunk> chunks = new ArrayList<>();
        List<RagEmbeddingTask> tasks = new ArrayList<>();
        for (Chunker.Chunk chunk : chunker.chunk(sourceDocument)) {
            RagChunk ragChunk = chunkService.upsert(document, chunk);
            RagEmbeddingTask task = embeddingTaskService.ensurePendingTask(ragChunk, upsert.aclChanged());
            if (!RagEmbeddingStatus.SUCCEEDED.equals(task.getStatus())) {
                chunkService.markPendingEmbedding(ragChunk);
            }
            chunks.add(ragChunk);
            tasks.add(task);
        }
        List<String> removedChunkIds = chunkService.replaceExcept(
                document.getId(),
                chunks.stream().map(RagChunk::getId).toList()
        );
        embeddingTaskService.deleteByChunkIds(removedChunkIds);
        documentService.markIndexed(document);
        new AfterCommitBoundary().afterCommit(() -> removeFromIndex(removedChunkIds));
        return new RagIndexingResult(document, List.copyOf(chunks), List.copyOf(tasks));
    }

    /** ES 里的向量文档必须随分块一起消失，删除失败只记日志：库里的分块才是权威数据。 */
    private void removeFromIndex(List<String> chunkIds) {
        for (String chunkId : chunkIds) {
            try {
                indexManager.deleteChunk(chunkId);
            } catch (RuntimeException error) {
                LOG.log(Level.WARNING, "Failed to delete RAG chunk from Elasticsearch: " + chunkId, error);
            }
        }
    }

    public record RagIndexingResult(
            RagDocument document,
            List<RagChunk> chunks,
            List<RagEmbeddingTask> embeddingTasks
    ) {
    }
}

@ApplicationScoped
class RagDocumentService {

    private static final Set<String> ACL_SCOPES = Set.of("PUBLIC", "ROLE", "USER", "DEPARTMENT");

    private final RagDocumentMapper mapper;

    RagDocumentService(RagDocumentMapper mapper) {
        this.mapper = mapper;
    }

    /**
     * 写入或更新文档。
     *
     * @param aclChanged 可见性相关的字段（acl_scope 与 metadata）是否发生变化；
     *                   变化时必须重新生成向量，否则 ES 里留着旧 ACL 的副本
     */
    record DocumentUpsert(RagDocument document, boolean aclChanged) {
    }

    DocumentUpsert upsert(RagSourceDocument source) {
        String id = RagHashSupport.stableId(
                "doc",
                source.sourceTable(),
                source.sourceId(),
                source.sourceVersion()
        );
        String contentHash = ChineseTextChunker.normalizedContentSha256Of(source.content());
        LocalDateTime now = LocalDateTime.now();
        RagDocument document = mapper.selectById(id);
        boolean insert = document == null;
        boolean aclChanged = insert || !sameAcl(document, source);
        if (insert) {
            document = new RagDocument();
            document.setId(id);
            document.setCreatedAt(now);
        }
        document.setSourceType(source.sourceType());
        document.setSourceTable(source.sourceTable());
        document.setSourceId(source.sourceId());
        document.setSourceVersion(source.sourceVersion());
        document.setTitle(source.title());
        document.setContentHash(contentHash);
        document.setStatus("READY");
        document.setAclScope(normalizeAclScope(source.aclScope()));
        document.setRoute(source.route());
        document.setMetadataJson(source.metadataJson());
        document.setUpdatedAt(now);
        if (insert) {
            mapper.insert(document);
        } else {
            mapper.updateById(document);
        }
        return new DocumentUpsert(document, aclChanged);
    }

    void markIndexed(RagDocument document) {
        document.setIndexedAt(LocalDateTime.now());
        document.setUpdatedAt(document.getIndexedAt());
        mapper.updateById(document);
    }

    private static boolean sameAcl(RagDocument document, RagSourceDocument source) {
        String scope = normalizeAclScope(source.aclScope());
        String metadata = source.metadataJson() == null ? "" : source.metadataJson();
        String storedScope = document.getAclScope() == null ? "" : document.getAclScope();
        String storedMetadata = document.getMetadataJson() == null ? "" : document.getMetadataJson();
        return scope.equals(storedScope) && metadata.equals(storedMetadata);
    }

    private static String normalizeAclScope(String aclScope) {
        String normalized = aclScope == null ? "PUBLIC" : aclScope.toUpperCase(Locale.ROOT);
        return ACL_SCOPES.contains(normalized) ? normalized : "PUBLIC";
    }
}

@ApplicationScoped
class RagChunkService {

    private final RagChunkMapper mapper;

    RagChunkService(RagChunkMapper mapper) {
        this.mapper = mapper;
    }

    List<String> replaceExcept(String documentId, List<String> keepIds) {
        Set<String> keep = new HashSet<>(keepIds == null ? List.of() : keepIds);
        List<RagChunk> existing = mapper.selectList(new QueryWrapper<RagChunk>().eq("document_id", documentId));
        List<String> removed = new ArrayList<>();
        for (RagChunk chunk : existing) {
            if (chunk.getId() == null || keep.contains(chunk.getId())) {
                continue;
            }
            mapper.deleteById(chunk.getId());
            removed.add(chunk.getId());
        }
        return removed;
    }

    RagChunk upsert(RagDocument document, Chunker.Chunk chunk) {
        String id = RagHashSupport.stableId(
                "chk",
                document.getId(),
                String.valueOf(chunk.chunkNo()),
                chunk.contentHash()
        );
        LocalDateTime now = LocalDateTime.now();
        RagChunk ragChunk = mapper.selectById(id);
        boolean insert = ragChunk == null;
        // 分块 id 由内容哈希决定：id 不变就说明内容没变，已有的向量仍然有效，不必重新排队。
        boolean contentUnchanged = !insert && chunk.contentHash().equals(ragChunk.getContentHash());
        if (insert) {
            ragChunk = new RagChunk();
            ragChunk.setId(id);
            ragChunk.setCreatedAt(now);
        }
        ragChunk.setDocumentId(document.getId());
        ragChunk.setChunkNo(chunk.chunkNo());
        ragChunk.setContent(chunk.content());
        ragChunk.setContentHash(chunk.contentHash());
        ragChunk.setTokenCount(chunk.tokenCount());
        ragChunk.setCharCount(chunk.charCount());
        ragChunk.setSourceField(chunk.sourceField());
        if (!contentUnchanged) {
            ragChunk.setStatus(RagEmbeddingStatus.CHUNK_PENDING_EMBEDDING);
        }
        ragChunk.setUpdatedAt(now);
        if (insert) {
            mapper.insert(ragChunk);
        } else {
            mapper.updateById(ragChunk);
        }
        return ragChunk;
    }

    /** 把分块退回待嵌入状态，检索侧据此排除还没写入 ES 的向量。 */
    void markPendingEmbedding(RagChunk chunk) {
        if (RagEmbeddingStatus.CHUNK_PENDING_EMBEDDING.equals(chunk.getStatus())) {
            return;
        }
        chunk.setStatus(RagEmbeddingStatus.CHUNK_PENDING_EMBEDDING);
        chunk.setUpdatedAt(LocalDateTime.now());
        mapper.updateById(chunk);
    }
}

@ApplicationScoped
class RagEmbeddingTaskService {

    static final String STATUS_PENDING = RagEmbeddingStatus.PENDING;
    static final String STATUS_SUCCEEDED = RagEmbeddingStatus.SUCCEEDED;

    private final RagEmbeddingTaskMapper mapper;
    private final RagProperties properties;

    @Inject
    RagEmbeddingTaskService(RagEmbeddingTaskMapper mapper, RagProperties properties) {
        this.mapper = mapper;
        this.properties = properties;
    }

    RagEmbeddingTaskService(RagEmbeddingTaskMapper mapper) {
        this(mapper, new RagProperties());
    }

    void deleteByChunkIds(List<String> chunkIds) {
        if (chunkIds == null || chunkIds.isEmpty()) {
            return;
        }
        List<RagEmbeddingTask> tasks = mapper.selectList(
                new QueryWrapper<RagEmbeddingTask>().in("chunk_id", chunkIds)
        );
        for (RagEmbeddingTask task : tasks) {
            if (task.getChunkId() != null && chunkIds.contains(task.getChunkId())) {
                mapper.deleteById(task.getId());
            }
        }
    }

    /**
     * 保证分块有且只有一条待处理任务。
     *
     * <p>任务键里含 provider 与 model，换模型会生成新键；这里按 chunk_id 复用最近的一条并清掉
     * 重复项，重复索引同一份内容不会把队列越堆越长。
     */
    RagEmbeddingTask ensurePendingTask(RagChunk chunk, boolean aclChanged) {
        String provider = normalize(properties.getEmbeddingProvider(), "unassigned");
        String model = normalize(properties.getEmbeddingModel(), "unassigned");
        LocalDateTime now = LocalDateTime.now();

        List<RagEmbeddingTask> existing = mapper.selectList(new QueryWrapper<RagEmbeddingTask>()
                .eq("chunk_id", chunk.getId())
                .orderByDesc("created_at"));
        RagEmbeddingTask task = existing.isEmpty() ? null : existing.get(0);
        for (int i = 1; i < existing.size(); i++) {
            mapper.deleteById(existing.get(i).getId());
        }

        if (task == null) {
            String taskKey = RagHashSupport.stableId("emb", chunk.getId(), provider, model);
            task = new RagEmbeddingTask();
            task.setId(taskKey);
            task.setChunkId(chunk.getId());
            task.setTaskKey(taskKey);
            task.setProvider(provider);
            task.setModel(model);
            task.setStatus(STATUS_PENDING);
            task.setAttemptCount(0);
            task.setCreatedAt(now);
            task.setUpdatedAt(now);
            mapper.insert(task);
            return task;
        }

        boolean upToDate = !aclChanged
                && STATUS_SUCCEEDED.equals(task.getStatus())
                && provider.equals(task.getProvider())
                && model.equals(task.getModel())
                && RagEmbeddingStatus.CHUNK_EMBEDDED.equals(chunk.getStatus());
        if (!upToDate) {
            UpdateWrapper<RagEmbeddingTask> wrapper = new UpdateWrapper<>();
            wrapper.set("provider", provider)
                    .set("model", model)
                    .set("status", STATUS_PENDING)
                    .set("attempt_count", 0)
                    .set("updated_at", now)
                    .setSql("next_retry_at = null")
                    .setSql("last_error = null")
                    .eq("id", task.getId());
            mapper.update(null, wrapper);
            task.setProvider(provider);
            task.setModel(model);
            task.setStatus(STATUS_PENDING);
            task.setAttemptCount(0);
            task.setNextRetryAt(null);
            task.setLastError(null);
            task.setUpdatedAt(now);
        }
        return task;
    }

    private static String normalize(String value, String fallback) {
        return value == null || value.isBlank() ? fallback : value.trim();
    }
}
