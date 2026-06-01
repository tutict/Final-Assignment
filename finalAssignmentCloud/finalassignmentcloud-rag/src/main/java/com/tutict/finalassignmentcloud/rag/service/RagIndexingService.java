package com.tutict.finalassignmentcloud.rag.service;

import com.tutict.finalassignmentcloud.rag.chunk.ChineseTextChunker;
import com.tutict.finalassignmentcloud.rag.chunk.Chunker;
import com.tutict.finalassignmentcloud.rag.config.RagProperties;
import com.tutict.finalassignmentcloud.rag.dto.RagSourceDocument;
import com.tutict.finalassignmentcloud.rag.entity.RagChunk;
import com.tutict.finalassignmentcloud.rag.entity.RagDocument;
import com.tutict.finalassignmentcloud.rag.entity.RagEmbeddingTask;
import com.tutict.finalassignmentcloud.rag.mapper.RagChunkMapper;
import com.tutict.finalassignmentcloud.rag.mapper.RagDocumentMapper;
import com.tutict.finalassignmentcloud.rag.mapper.RagEmbeddingTaskMapper;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.HexFormat;
import java.util.List;
import java.util.Locale;
import java.util.Set;

@Service
@ConditionalOnProperty(prefix = "rag", name = "enabled", havingValue = "true")
public class RagIndexingService {

    private final RagDocumentService documentService;
    private final RagChunkService chunkService;
    private final RagEmbeddingTaskService embeddingTaskService;
    private final Chunker chunker;

    public RagIndexingService(
            RagDocumentService documentService,
            RagChunkService chunkService,
            RagEmbeddingTaskService embeddingTaskService,
            Chunker chunker
    ) {
        this.documentService = documentService;
        this.chunkService = chunkService;
        this.embeddingTaskService = embeddingTaskService;
        this.chunker = chunker;
    }

    @Transactional
    public RagIndexingResult index(RagSourceDocument sourceDocument) {
        RagDocument document = documentService.upsert(sourceDocument);
        List<RagChunk> chunks = new ArrayList<>();
        List<RagEmbeddingTask> tasks = new ArrayList<>();
        for (Chunker.Chunk chunk : chunker.chunk(sourceDocument)) {
            RagChunk ragChunk = chunkService.upsert(document, chunk);
            chunks.add(ragChunk);
            tasks.add(embeddingTaskService.ensurePendingTask(ragChunk));
        }
        documentService.markIndexed(document);
        return new RagIndexingResult(document, List.copyOf(chunks), List.copyOf(tasks));
    }

    public record RagIndexingResult(
            RagDocument document,
            List<RagChunk> chunks,
            List<RagEmbeddingTask> embeddingTasks
    ) {
    }
}

@Service
@ConditionalOnProperty(prefix = "rag", name = "enabled", havingValue = "true")
class RagDocumentService {

    private static final Set<String> ACL_SCOPES = Set.of("PUBLIC", "ROLE", "USER", "DEPARTMENT");

    private final RagDocumentMapper mapper;

    RagDocumentService(RagDocumentMapper mapper) {
        this.mapper = mapper;
    }

    RagDocument upsert(RagSourceDocument source) {
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
        return document;
    }

    void markIndexed(RagDocument document) {
        document.setIndexedAt(LocalDateTime.now());
        document.setUpdatedAt(document.getIndexedAt());
        mapper.updateById(document);
    }

    private static String normalizeAclScope(String aclScope) {
        String normalized = aclScope == null ? "PUBLIC" : aclScope.toUpperCase(Locale.ROOT);
        return ACL_SCOPES.contains(normalized) ? normalized : "PUBLIC";
    }
}

@Service
@ConditionalOnProperty(prefix = "rag", name = "enabled", havingValue = "true")
class RagChunkService {

    private final RagChunkMapper mapper;

    RagChunkService(RagChunkMapper mapper) {
        this.mapper = mapper;
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
        ragChunk.setStatus("PENDING_EMBEDDING");
        ragChunk.setUpdatedAt(now);
        if (insert) {
            mapper.insert(ragChunk);
        } else {
            mapper.updateById(ragChunk);
        }
        return ragChunk;
    }
}

@Service
@ConditionalOnProperty(prefix = "rag", name = "enabled", havingValue = "true")
class RagEmbeddingTaskService {

    static final String STATUS_PENDING = "PENDING";
    static final String STATUS_RUNNING = "RUNNING";
    static final String STATUS_SUCCEEDED = "SUCCEEDED";
    static final String STATUS_FAILED = "FAILED";
    static final String STATUS_POISONED = "POISONED";

    private final RagEmbeddingTaskMapper mapper;
    private final RagProperties properties;

    @Autowired
    RagEmbeddingTaskService(RagEmbeddingTaskMapper mapper, RagProperties properties) {
        this.mapper = mapper;
        this.properties = properties;
    }

    RagEmbeddingTaskService(RagEmbeddingTaskMapper mapper) {
        this(mapper, new RagProperties());
    }

    RagEmbeddingTask ensurePendingTask(RagChunk chunk) {
        String provider = normalize(properties.getEmbedding().getProvider(), "unassigned");
        String model = normalize(properties.getEmbedding().getModel(), "unassigned");
        String taskKey = RagHashSupport.stableId(
                "emb",
                chunk.getId(),
                provider,
                model
        );
        LocalDateTime now = LocalDateTime.now();
        RagEmbeddingTask task = mapper.selectById(taskKey);
        if (task != null) {
            if (!STATUS_SUCCEEDED.equals(task.getStatus())) {
                task.setStatus(STATUS_PENDING);
                task.setNextRetryAt(null);
            }
            task.setUpdatedAt(now);
            mapper.updateById(task);
            return task;
        }

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

    private static String normalize(String value, String fallback) {
        return value == null || value.isBlank() ? fallback : value.trim();
    }
}

final class RagHashSupport {

    private static final String DELIMITER = "\u001F";

    private RagHashSupport() {
    }

    static String stableId(String prefix, String... parts) {
        return prefix + "_" + sha256Hex(String.join(DELIMITER, parts)).substring(0, 32);
    }

    private static String sha256Hex(String value) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            return HexFormat.of().formatHex(digest.digest(value.getBytes(StandardCharsets.UTF_8)));
        } catch (NoSuchAlgorithmException error) {
            throw new IllegalStateException("SHA-256 is not available", error);
        }
    }
}

