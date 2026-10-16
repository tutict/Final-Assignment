package com.tutict.finalassignmentbackend.ai.rag.retrieval;

import com.tutict.finalassignmentbackend.ai.rag.config.RagRetrievalProperties;
import com.tutict.finalassignmentbackend.ai.rag.dto.RetrievalResult;
import com.tutict.finalassignmentbackend.ai.rag.rerank.LightweightRerankProvider;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.util.ArrayList;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * RAG 检索质量评测：以金标集（{@code rag-eval/golden-set.json}）驱动生产检索链路，
 * 计算 recall@k / precision@k / MRR / nDCG@k，并校验 ACL 不泄漏。
 *
 * <p>这是"RAG 可评测"的落地：任何改动只要让检索变差或让受限文档泄漏，CI 即失败。
 */
class RagRetrievalQualityTest {

    private static final String GOLDEN_SET = "/rag-eval/golden-set.json";
    private static final int TOP_K = 5;
    private static final int EMBEDDING_DIMENSIONS = 1024;

    private static RagEvalDataset dataset;
    private static HybridRetriever retriever;
    private static EmbeddingSearchService searchService;
    private static AclFilterService aclFilterService;

    @BeforeAll
    static void setUp() {
        dataset = RagEvalDataset.load(GOLDEN_SET);
        RagRetrievalProperties properties = productionProperties();
        aclFilterService = new AclFilterService();
        EmbeddingProvider embeddingProvider = new HashingBagOfWordsEmbedding(EMBEDDING_DIMENSIONS);
        searchService = new EmbeddingSearchService(
                embeddingProvider,
                new InMemoryRagSearchBackend(dataset.corpus(), embeddingProvider)
        );
        retriever = new HybridRetriever(
                searchService,
                aclFilterService,
                new LightweightRerankProvider(properties),
                properties
        );
    }

    @Test
    @DisplayName("hybrid retrieval meets recall/MRR/nDCG thresholds on the golden set")
    void hybridRetrievalMeetsQualityThresholds() {
        List<Double> recallAt1 = new ArrayList<>();
        List<Double> recallAt3 = new ArrayList<>();
        List<Double> recallAt5 = new ArrayList<>();
        List<Double> precision = new ArrayList<>();
        List<Double> mrr = new ArrayList<>();
        List<Double> ndcg = new ArrayList<>();
        List<String> misses = new ArrayList<>();

        for (RagEvalDataset.EvalQuery query : dataset.qualityQueries()) {
            List<String> retrieved = retrieve(query);
            recallAt1.add(RagRetrievalMetrics.recallAtK(retrieved, query.relevantChunkIds(), 1));
            recallAt3.add(RagRetrievalMetrics.recallAtK(retrieved, query.relevantChunkIds(), 3));
            recallAt5.add(RagRetrievalMetrics.recallAtK(retrieved, query.relevantChunkIds(), TOP_K));
            precision.add(RagRetrievalMetrics.precisionAtK(retrieved, query.relevantChunkIds(), TOP_K));
            mrr.add(RagRetrievalMetrics.reciprocalRank(retrieved, query.relevantChunkIds()));
            ndcg.add(RagRetrievalMetrics.ndcgAtK(retrieved, query.relevantChunkIds(), TOP_K));
            if (RagRetrievalMetrics.recallAtK(retrieved, query.relevantChunkIds(), TOP_K) < 1.0) {
                misses.add(String.format("  %s '%s' expected=%s got=%s",
                        query.id(), query.query(), query.relevantChunkIds(), retrieved));
            }
        }

        double meanRecall1 = RagRetrievalMetrics.mean(recallAt1);
        double meanRecall3 = RagRetrievalMetrics.mean(recallAt3);
        double meanRecall5 = RagRetrievalMetrics.mean(recallAt5);
        double meanPrecision = RagRetrievalMetrics.mean(precision);
        double meanMrr = RagRetrievalMetrics.mean(mrr);
        double meanNdcg = RagRetrievalMetrics.mean(ndcg);

        System.out.printf(
                "[rag-eval] queries=%d recall@1=%.3f recall@3=%.3f recall@%d=%.3f precision@%d=%.3f MRR=%.3f nDCG@%d=%.3f%n",
                recallAt5.size(), meanRecall1, meanRecall3, TOP_K, meanRecall5,
                TOP_K, meanPrecision, meanMrr, TOP_K, meanNdcg);
        if (!misses.isEmpty()) {
            System.out.println("[rag-eval] queries with missed relevant chunks:");
            misses.forEach(System.out::println);
        }

        assertThat(meanRecall5).as("macro recall@%d", TOP_K).isGreaterThanOrEqualTo(0.95);
        assertThat(meanRecall3).as("macro recall@3").isGreaterThanOrEqualTo(0.85);
        assertThat(meanMrr).as("macro MRR").isGreaterThanOrEqualTo(0.85);
        assertThat(meanNdcg).as("macro nDCG@%d", TOP_K).isGreaterThanOrEqualTo(0.85);
        assertThat(meanPrecision).as("macro precision@%d", TOP_K).isGreaterThanOrEqualTo(0.15);
    }

    @Test
    @DisplayName("retrieval never returns chunks the caller is not allowed to see")
    void retrievalNeverLeaksAclRestrictedChunks() {
        List<String> leaks = new ArrayList<>();
        for (RagEvalDataset.EvalQuery query : dataset.queries()) {
            List<String> retrieved = retrieve(query);
            for (String forbidden : query.mustNotReturn()) {
                if (retrieved.contains(forbidden)) {
                    leaks.add(String.format("  %s '%s' leaked %s (got=%s)", query.id(), query.query(), forbidden, retrieved));
                }
            }
        }
        if (!leaks.isEmpty()) {
            System.out.println("[rag-eval] ACL leaks detected:");
            leaks.forEach(System.out::println);
        }
        assertThat(leaks).as("ACL-restricted chunks returned to unauthorized callers").isEmpty();
    }

    @Test
    @DisplayName("hybrid fusion is not worse than BM25-only on the golden set")
    void hybridFusionIsNotWorseThanBm25Only() {
        double hybridRecall = 0;
        double bm25Recall = 0;
        int count = 0;
        for (RagEvalDataset.EvalQuery query : dataset.qualityQueries()) {
            List<String> hybrid = retrieve(query);
            List<String> bm25Only = searchService.bm25Search(
                    query.query(),
                    aclFilterService.buildFilter(query.accessContext()),
                    TOP_K
            ).stream().map(RetrievalResult::chunkId).toList();
            hybridRecall += RagRetrievalMetrics.recallAtK(hybrid, query.relevantChunkIds(), TOP_K);
            bm25Recall += RagRetrievalMetrics.recallAtK(bm25Only, query.relevantChunkIds(), TOP_K);
            count++;
        }
        double hybridMean = count == 0 ? 0 : hybridRecall / count;
        double bm25Mean = count == 0 ? 0 : bm25Recall / count;
        System.out.printf("[rag-eval] ablation recall@%d hybrid=%.3f bm25-only=%.3f%n", TOP_K, hybridMean, bm25Mean);
        assertThat(hybridMean).as("hybrid recall must not trail BM25-only").isGreaterThanOrEqualTo(bm25Mean - 0.02);
    }

    private static List<String> retrieve(RagEvalDataset.EvalQuery query) {
        List<RetrievalResult> results = retriever.retrieve(
                new RetrievalQuery(query.query(), query.accessContext(), TOP_K)
        );
        Set<String> ids = new LinkedHashSet<>();
        results.forEach(result -> ids.add(result.chunkId()));
        return List.copyOf(ids);
    }

    private static RagRetrievalProperties productionProperties() {
        RagRetrievalProperties properties = new RagRetrievalProperties();
        properties.setTopK(TOP_K);
        properties.setVectorWeight(0.6);
        properties.setBm25Weight(0.4);
        properties.setMinScore(0.2);
        properties.setCandidateMultiplier(3);
        properties.setRrfRankConstant(60);
        properties.setRerankEnabled(true);
        properties.setRerankLexicalWeight(0.15);
        return properties;
    }
}