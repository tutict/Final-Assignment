package finalassignmentbackend.rag.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import finalassignmentbackend.mapper.RagChunkMapper;
import finalassignmentbackend.mapper.RagDocumentMapper;
import finalassignmentbackend.rag.access.RagAccessContext;
import finalassignmentbackend.rag.access.RagAclPolicy;
import finalassignmentbackend.rag.embedding.RagEmbeddingStatus;
import finalassignmentbackend.rag.entity.RagChunk;
import finalassignmentbackend.rag.entity.RagDocument;
import finalassignmentbackend.rag.retrieval.RagSearchHit;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

/**
 * 按分块 id 回读 MySQL，并对 ES 命中的候选做严格收敛。
 *
 * <p>ES 侧只做粗过滤，真正的可见性以库里的文档为准：分块必须已经嵌入、文档必须就绪，
 * 而且必须通过 metadata 里的 ACL 名单判定。这样即使索引里残留了旧文档，也不会召回越权内容。
 */
@ApplicationScoped
public class MySqlRagCandidateStore {

    @Inject RagChunkMapper chunkMapper;
    @Inject RagDocumentMapper documentMapper;

    /** 一次回读命中的候选。 */
    public record Candidate(
            String chunkId,
            String documentId,
            String sourceId,
            String content,
            String title,
            String sourceType,
            String route,
            double finalScore
    ) {
    }

    public List<Candidate> resolve(List<RagSearchHit> hits, RagAccessContext context) {
        if (hits == null || hits.isEmpty()) {
            return List.of();
        }
        Map<String, Double> scores = new LinkedHashMap<>();
        for (RagSearchHit hit : hits) {
            if (hit.chunkId() != null && !hit.chunkId().isBlank()) {
                scores.putIfAbsent(hit.chunkId(), hit.finalScore());
            }
        }
        if (scores.isEmpty()) {
            return List.of();
        }
        List<RagChunk> chunks = chunkMapper.selectList(
                new QueryWrapper<RagChunk>().in("id", scores.keySet())
        );
        if (chunks == null || chunks.isEmpty()) {
            return List.of();
        }
        Map<String, RagChunk> chunkById = new LinkedHashMap<>();
        Set<String> documentIds = new LinkedHashSet<>();
        for (RagChunk chunk : chunks) {
            chunkById.put(chunk.getId(), chunk);
            if (chunk.getDocumentId() != null) {
                documentIds.add(chunk.getDocumentId());
            }
        }
        Map<String, RagDocument> documents = new LinkedHashMap<>();
        if (!documentIds.isEmpty()) {
            List<RagDocument> loaded = documentMapper.selectList(
                    new QueryWrapper<RagDocument>().in("id", documentIds)
            );
            if (loaded != null) {
                for (RagDocument document : loaded) {
                    documents.put(document.getId(), document);
                }
            }
        }
        List<Candidate> candidates = new ArrayList<>();
        for (Map.Entry<String, Double> entry : scores.entrySet()) {
            RagChunk chunk = chunkById.get(entry.getKey());
            if (chunk == null || !RagEmbeddingStatus.CHUNK_EMBEDDED.equals(chunk.getStatus())) {
                continue;
            }
            RagDocument document = documents.get(chunk.getDocumentId());
            if (document == null || !"READY".equals(document.getStatus())) {
                continue;
            }
            if (!RagAdminDocumentSupport.isKnowledgeDocument(document)) {
                continue;
            }
            if (!RagAclPolicy.allows(RagAclPolicy.parse(document), context)) {
                continue;
            }
            candidates.add(new Candidate(
                    chunk.getId(),
                    document.getId(),
                    document.getSourceId(),
                    chunk.getContent(),
                    document.getTitle(),
                    document.getSourceType(),
                    document.getRoute(),
                    entry.getValue()
            ));
        }
        return candidates;
    }
}
