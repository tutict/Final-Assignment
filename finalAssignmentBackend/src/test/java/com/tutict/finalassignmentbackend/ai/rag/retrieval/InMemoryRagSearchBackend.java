package com.tutict.finalassignmentbackend.ai.rag.retrieval;

import com.tutict.finalassignmentbackend.ai.rag.dto.RetrievalResult;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * 内存检索后端：对受控语料实现真实的 BM25 词法检索与向量余弦检索，并复用生产
 * {@link AclFilterService} 的 ACL 判定。
 *
 * <p>它替换生产中的 Elasticsearch 后端，使离线评测可在 CI 中运行。评测覆盖的仍是生产
 * 代码路径：{@link EmbeddingSearchService} → {@link HybridRetriever} 的融合、去重、minScore
 * 过滤、rerank 与 ACL 过滤。
 */
final class InMemoryRagSearchBackend implements RagSearchBackend {

    private static final double BM25_K1 = 1.2;
    private static final double BM25_B = 0.75;

    private final AclFilterService aclFilterService = new AclFilterService();
    private final List<IndexedChunk> chunks;
    private final Map<String, Integer> documentFrequency;
    private final double averageLength;

    InMemoryRagSearchBackend(List<RagEvalDataset.EvalChunk> corpus, EmbeddingProvider embeddingProvider) {
        this.chunks = new ArrayList<>();
        this.documentFrequency = new HashMap<>();
        double totalLength = 0;
        for (RagEvalDataset.EvalChunk chunk : corpus) {
            List<String> tokens = EvalTokenizer.tokens(chunk.searchableText());
            Map<String, Integer> termFrequency = new HashMap<>();
            for (String token : tokens) {
                termFrequency.merge(token, 1, Integer::sum);
            }
            termFrequency.keySet().forEach(term -> documentFrequency.merge(term, 1, Integer::sum));
            totalLength += tokens.size();
            this.chunks.add(new IndexedChunk(chunk, termFrequency, tokens.size(), embeddingProvider.embed(chunk.searchableText())));
        }
        this.averageLength = chunks.isEmpty() ? 1 : totalLength / chunks.size();
    }

    @Override
    public List<RetrievalResult> bm25Search(String normalizedQuery, AclFilterService.AclFilter aclFilter, int limit) {
        List<String> queryTokens = EvalTokenizer.tokens(normalizedQuery);
        if (queryTokens.isEmpty()) {
            return List.of();
        }
        List<Scored> scored = new ArrayList<>();
        for (IndexedChunk chunk : chunks) {
            double score = bm25(queryTokens, chunk);
            if (score > 0 && allows(chunk, aclFilter)) {
                scored.add(new Scored(chunk, score));
            }
        }
        return topResults(scored, limit, true);
    }

    @Override
    public List<RetrievalResult> vectorSearch(float[] queryVector, AclFilterService.AclFilter aclFilter, int limit) {
        List<Scored> scored = new ArrayList<>();
        for (IndexedChunk chunk : chunks) {
            double score = cosine(queryVector, chunk.embedding());
            if (score > 0 && allows(chunk, aclFilter)) {
                scored.add(new Scored(chunk, score));
            }
        }
        return topResults(scored, limit, false);
    }

    private List<RetrievalResult> topResults(List<Scored> scored, int limit, boolean bm25Mode) {
        return scored.stream()
                .sorted(Comparator.comparingDouble(Scored::score).reversed()
                        .thenComparing(scoredChunk -> scoredChunk.chunk().chunk().chunkId()))
                .limit(Math.max(1, limit))
                .map(hit -> toResult(hit.chunk().chunk(), hit.score(), bm25Mode))
                .toList();
    }

    private boolean allows(IndexedChunk chunk, AclFilterService.AclFilter aclFilter) {
        AclFilterService.AccessContext context = new AclFilterService.AccessContext(
                aclFilter.userId(), aclFilter.roles(), aclFilter.department());
        return aclFilterService.allows(toResult(chunk.chunk(), 0, true), context);
    }

    private double bm25(List<String> queryTokens, IndexedChunk chunk) {
        double score = 0;
        int total = chunks.size();
        for (String term : queryTokens) {
            Integer tf = chunk.termFrequency().get(term);
            if (tf == null) {
                continue;
            }
            int df = documentFrequency.getOrDefault(term, 0);
            double idf = Math.log(1 + (total - df + 0.5) / (df + 0.5));
            double denominator = tf + BM25_K1 * (1 - BM25_B + BM25_B * chunk.length() / averageLength);
            score += idf * (tf * (BM25_K1 + 1)) / denominator;
        }
        return score;
    }

    private static double cosine(float[] left, float[] right) {
        double dot = 0;
        int length = Math.min(left.length, right.length);
        for (int i = 0; i < length; i++) {
            dot += left[i] * right[i];
        }
        return dot;
    }

    private static RetrievalResult toResult(RagEvalDataset.EvalChunk chunk, double score, boolean bm25Mode) {
        Map<String, Object> metadata = new LinkedHashMap<>();
        metadata.put("aclScope", chunk.aclScope());
        if (!chunk.aclRoles().isEmpty()) {
            metadata.put("aclRoles", chunk.aclRoles());
        }
        if (!chunk.aclUserIds().isEmpty()) {
            metadata.put("aclUserIds", chunk.aclUserIds());
        }
        if (!chunk.aclDepartments().isEmpty()) {
            metadata.put("aclDepartments", chunk.aclDepartments());
        }
        return new RetrievalResult(
                chunk.chunkId(),
                chunk.documentId(),
                chunk.content(),
                chunk.title(),
                chunk.sourceType(),
                "rag",
                chunk.chunkId(),
                chunk.sourceField(),
                chunk.route(),
                bm25Mode ? score : 0,
                bm25Mode ? 0 : score,
                0,
                metadata
        );
    }

    private record IndexedChunk(
            RagEvalDataset.EvalChunk chunk,
            Map<String, Integer> termFrequency,
            int length,
            float[] embedding
    ) {
    }

    private record Scored(IndexedChunk chunk, double score) {
    }
}