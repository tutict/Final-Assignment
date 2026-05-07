package com.tutict.finalassignmentbackend.ai.rag.retrieval;

import com.tutict.finalassignmentbackend.ai.rag.config.RagRetrievalProperties;
import com.tutict.finalassignmentbackend.ai.rag.dto.RetrievalResult;
import com.tutict.finalassignmentbackend.ai.rag.rerank.NoopRerankProvider;
import org.springframework.stereotype.Service;

import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@Service
public class HybridRetriever {

    private final EmbeddingSearchService embeddingSearchService;
    private final AclFilterService aclFilterService;
    private final NoopRerankProvider rerankProvider;
    private final RagRetrievalProperties properties;

    public HybridRetriever(
            EmbeddingSearchService embeddingSearchService,
            AclFilterService aclFilterService,
            NoopRerankProvider rerankProvider,
            RagRetrievalProperties properties
    ) {
        this.embeddingSearchService = embeddingSearchService;
        this.aclFilterService = aclFilterService;
        this.rerankProvider = rerankProvider;
        this.properties = properties;
    }

    public List<RetrievalResult> retrieve(RetrievalQuery query) {
        AclFilterService.AclFilter aclFilter = aclFilterService.buildFilter(query.accessContext());
        int candidateLimit = Math.max(query.topK() * 2, query.topK());
        float[] queryVector = embeddingSearchService.embedQuery(query.normalizedQuery());
        List<RetrievalResult> bm25Results = embeddingSearchService.bm25Search(
                query.normalizedQuery(),
                aclFilter,
                candidateLimit
        );
        List<RetrievalResult> vectorResults = embeddingSearchService.vectorSearch(
                queryVector,
                aclFilter,
                candidateLimit
        );
        return rerankProvider.rerank(
                query.normalizedQuery(),
                fuseResults(bm25Results, vectorResults, query.accessContext(), query.topK())
        );
    }

    public List<RetrievalResult> fuseResults(
            List<RetrievalResult> bm25Results,
            List<RetrievalResult> vectorResults,
            AclFilterService.AccessContext accessContext,
            int topK
    ) {
        Map<String, ScoreAccumulator> byChunkId = new LinkedHashMap<>();
        bm25Results.forEach(result -> byChunkId.computeIfAbsent(
                result.chunkId(),
                ignored -> new ScoreAccumulator(result)
        ).bm25Score = Math.max(byChunkId.get(result.chunkId()).bm25Score, result.bm25Score()));
        vectorResults.forEach(result -> byChunkId.computeIfAbsent(
                result.chunkId(),
                ignored -> new ScoreAccumulator(result)
        ).vectorScore = Math.max(byChunkId.get(result.chunkId()).vectorScore, result.vectorScore()));

        return byChunkId.values().stream()
                .map(accumulator -> accumulator.result.withScores(
                        accumulator.bm25Score,
                        accumulator.vectorScore,
                        accumulator.bm25Score * properties.getBm25Weight()
                                + accumulator.vectorScore * properties.getVectorWeight()
                ))
                .filter(result -> result.finalScore() >= properties.getMinScore())
                .filter(result -> aclFilterService.allows(result, accessContext))
                .sorted(Comparator.comparingDouble(RetrievalResult::finalScore).reversed())
                .limit(Math.max(1, topK))
                .toList();
    }

    private static final class ScoreAccumulator {
        private final RetrievalResult result;
        private double bm25Score;
        private double vectorScore;

        private ScoreAccumulator(RetrievalResult result) {
            this.result = result;
            this.bm25Score = result.bm25Score();
            this.vectorScore = result.vectorScore();
        }
    }
}
