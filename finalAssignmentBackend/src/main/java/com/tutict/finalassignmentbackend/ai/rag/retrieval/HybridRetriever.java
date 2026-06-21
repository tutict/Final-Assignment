package com.tutict.finalassignmentbackend.ai.rag.retrieval;

import com.tutict.finalassignmentbackend.ai.rag.config.RagRetrievalProperties;
import com.tutict.finalassignmentbackend.ai.rag.dto.RetrievalResult;
import com.tutict.finalassignmentbackend.ai.rag.rerank.RerankProvider;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Service;

import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@Service
@ConditionalOnProperty(prefix = "rag.retrieval", name = "enabled", havingValue = "true")
public class HybridRetriever {

    private final EmbeddingSearchService embeddingSearchService;
    private final AclFilterService aclFilterService;
    private final RerankProvider rerankProvider;
    private final RagRetrievalProperties properties;

    public HybridRetriever(
            EmbeddingSearchService embeddingSearchService,
            AclFilterService aclFilterService,
            RerankProvider rerankProvider,
            RagRetrievalProperties properties
    ) {
        this.embeddingSearchService = embeddingSearchService;
        this.aclFilterService = aclFilterService;
        this.rerankProvider = rerankProvider;
        this.properties = properties;
    }

    public List<RetrievalResult> retrieve(RetrievalQuery query) {
        AclFilterService.AclFilter aclFilter = aclFilterService.buildFilter(query.accessContext());
        int candidateLimit = Math.max(
                query.topK(),
                query.topK() * Math.max(1, properties.getCandidateMultiplier())
        );
        List<RetrievalResult> bm25Results = embeddingSearchService.bm25Search(
                query.normalizedQuery(),
                aclFilter,
                candidateLimit
        );
        List<RetrievalResult> vectorResults = vectorResults(query, aclFilter, candidateLimit);
        return rerankProvider.rerank(
                query.normalizedQuery(),
                fuseResults(bm25Results, vectorResults, query.accessContext(), query.topK())
        );
    }

    private List<RetrievalResult> vectorResults(
            RetrievalQuery query,
            AclFilterService.AclFilter aclFilter,
            int candidateLimit
    ) {
        try {
            float[] queryVector = embeddingSearchService.embedQuery(query.normalizedQuery());
            return embeddingSearchService.vectorSearch(queryVector, aclFilter, candidateLimit);
        } catch (RuntimeException error) {
            return List.of();
        }
    }

    public List<RetrievalResult> fuseResults(
            List<RetrievalResult> bm25Results,
            List<RetrievalResult> vectorResults,
            AclFilterService.AccessContext accessContext,
            int topK
    ) {
        Map<String, ScoreAccumulator> byChunkId = new LinkedHashMap<>();
        accumulateRankScores(byChunkId, bm25Results, true);
        accumulateRankScores(byChunkId, vectorResults, false);

        return byChunkId.values().stream()
                .map(accumulator -> accumulator.result.withScores(
                        accumulator.bm25Score,
                        accumulator.vectorScore,
                        accumulator.rrfScore
                ))
                .filter(result -> result.finalScore() >= properties.getMinScore())
                .filter(result -> aclFilterService.allows(result, accessContext))
                .sorted(Comparator.comparingDouble(RetrievalResult::finalScore).reversed())
                .limit(Math.max(1, topK))
                .toList();
    }

    private void accumulateRankScores(
            Map<String, ScoreAccumulator> byChunkId,
            List<RetrievalResult> results,
            boolean bm25
    ) {
        for (int index = 0; index < results.size(); index++) {
            RetrievalResult result = results.get(index);
            ScoreAccumulator accumulator = byChunkId.computeIfAbsent(
                    result.chunkId(),
                    ignored -> new ScoreAccumulator(result)
            );
            if (bm25) {
                accumulator.bm25Score = Math.max(accumulator.bm25Score, result.bm25Score());
                accumulator.rrfScore += reciprocalRankScore(index + 1, properties.getBm25Weight());
            } else {
                accumulator.vectorScore = Math.max(accumulator.vectorScore, result.vectorScore());
                accumulator.rrfScore += reciprocalRankScore(index + 1, properties.getVectorWeight());
            }
        }
    }

    private double reciprocalRankScore(int rank, double weight) {
        int rankConstant = Math.max(1, properties.getRrfRankConstant());
        return 100.0 * Math.max(0, weight) / (rankConstant + Math.max(1, rank));
    }

    private static final class ScoreAccumulator {
        private final RetrievalResult result;
        private double bm25Score;
        private double vectorScore;
        private double rrfScore;

        private ScoreAccumulator(RetrievalResult result) {
            this.result = result;
            this.bm25Score = result.bm25Score();
            this.vectorScore = result.vectorScore();
        }
    }
}
