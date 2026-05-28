package com.tutict.finalassignmentbackend.ai.rag.retrieval;

import com.tutict.finalassignmentbackend.ai.rag.config.RagRetrievalProperties;
import com.tutict.finalassignmentbackend.ai.rag.dto.RetrievalResult;
import com.tutict.finalassignmentbackend.ai.rag.rerank.LightweightRerankProvider;
import org.junit.jupiter.api.Test;

import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

class HybridRetrieverTest {

    @Test
    void mergesBm25AndVectorDeduplicatesAndReturnsTopK() {
        RagRetrievalProperties properties = properties();
        EmbeddingSearchService searchService = new EmbeddingSearchService(
                new StaticEmbeddingProvider(vector()),
                new FakeBackend(
                        List.of(result("a", 0.9, 0, "PUBLIC"), result("b", 0.6, 0, "PUBLIC")),
                        List.of(result("a", 0, 0.8, "PUBLIC"), result("c", 0, 0.7, "PUBLIC"))
                )
        );
        HybridRetriever retriever = new HybridRetriever(
                searchService,
                new AclFilterService(),
                new LightweightRerankProvider(properties),
                properties
        );

        List<RetrievalResult> results = retriever.retrieve(
                new RetrievalQuery("query", new AclFilterService.AccessContext("u1", java.util.Set.of(), null), 2)
        );

        assertThat(results).extracting(RetrievalResult::chunkId).containsExactly("a", "c");
        assertThat(Math.abs(results.getFirst().finalScore() - rrfScore(1, 0.4, 60) - rrfScore(1, 0.6, 60)))
                .isLessThan(0.0001);
    }

    private static float[] vector() {
        return new float[]{1, 0, 0};
    }

    private static double rrfScore(int rank, double weight, int rankConstant) {
        return 100.0 * weight / (rankConstant + rank);
    }

    private static RagRetrievalProperties properties() {
        RagRetrievalProperties properties = new RagRetrievalProperties();
        properties.setMinScore(0);
        properties.setRerankEnabled(false);
        return properties;
    }

    private static RetrievalResult result(String chunkId, double bm25, double vector, String scope) {
        return new RetrievalResult(
                chunkId,
                "doc-" + chunkId,
                "content",
                "title",
                "BUSINESS",
                "rag",
                chunkId,
                "content",
                "/r/" + chunkId,
                bm25,
                vector,
                0,
                Map.of("aclScope", scope)
        );
    }
}

class AclFilterServiceTest {

    @Test
    void appliesPublicRoleUserAndDepartmentAccess() {
        AclFilterService service = new AclFilterService();
        AclFilterService.AccessContext context = service.context("u1", List.of("admin"), "traffic");

        assertThat(service.allows(result("PUBLIC", Map.of()), context)).isTrue();
        assertThat(service.allows(result("ROLE", Map.of("roles", List.of("admin"))), context)).isTrue();
        assertThat(service.allows(result("ROLE", Map.of("roles", List.of("guest"))), context)).isFalse();
        assertThat(service.allows(result("USER", Map.of("userIds", List.of("u1"))), context)).isTrue();
        assertThat(service.allows(result("DEPARTMENT", Map.of("departments", List.of("traffic"))), context)).isTrue();
    }

    private static RetrievalResult result(String scope, Map<String, Object> metadata) {
        java.util.Map<String, Object> values = new java.util.LinkedHashMap<>(metadata);
        values.put("aclScope", scope);
        return new RetrievalResult("c", "d", "content", "title", "BUSINESS", "t", "1",
                "content", "/r", 0, 0, 0, values);
    }
}

class ScoreFusionTest {

    @Test
    void usesConfiguredWeightedScore() {
        RagRetrievalProperties properties = new RagRetrievalProperties();
        properties.setBm25Weight(0.4);
        properties.setVectorWeight(0.6);
        properties.setMinScore(0);
        HybridRetriever retriever = new HybridRetriever(
                new EmbeddingSearchService(new StaticEmbeddingProvider(new float[]{1}), new FakeBackend(List.of(), List.of())),
                new AclFilterService(),
                new LightweightRerankProvider(properties),
                properties
        );

        List<RetrievalResult> results = retriever.fuseResults(
                List.of(result("c1", 0.5, 0)),
                List.of(result("c1", 0, 0.9)),
                new AclFilterService.AccessContext(null, java.util.Set.of(), null),
                10
        );

        assertThat(results).hasSize(1);
        assertThat(Math.abs(results.getFirst().finalScore() - rrfScore(1, 0.4, 60) - rrfScore(1, 0.6, 60)))
                .isLessThan(0.0001);
    }

    private static RetrievalResult result(String chunkId, double bm25, double vector) {
        return new RetrievalResult(chunkId, "d", "content", "title", "BUSINESS", "t", "1",
                "content", "/r", bm25, vector, 0, Map.of("aclScope", "PUBLIC"));
    }

    private static double rrfScore(int rank, double weight, int rankConstant) {
        return 100.0 * weight / (rankConstant + rank);
    }
}

class RerankProviderTest {

    @Test
    void boostsLexicalMatchesAfterHybridFusion() {
        RagRetrievalProperties properties = new RagRetrievalProperties();
        properties.setRerankEnabled(true);
        properties.setRerankLexicalWeight(0.5);
        LightweightRerankProvider rerankProvider = new LightweightRerankProvider(properties);

        List<RetrievalResult> results = rerankProvider.rerank(
                "parking fine",
                List.of(
                        result("a", "accident handling", "accident quick process guide", 1.0),
                        result("b", "parking fine payment", "online payment portal and process steps", 0.95)
                )
        );

        assertThat(results).extracting(RetrievalResult::chunkId).containsExactly("b", "a");
    }

    private static RetrievalResult result(String chunkId, String title, String content, double score) {
        return new RetrievalResult(chunkId, "d", content, title, "BUSINESS", "t", "1",
                "content", "/r", 0, 0, score, Map.of("aclScope", "PUBLIC"));
    }
}

class EmbeddingSearchServiceTest {

    @Test
    void delegatesEmbeddingBm25AndVectorSearch() {
        FakeEmbeddingProvider embeddingProvider = new FakeEmbeddingProvider();
        FakeBackend backend = new FakeBackend(
                List.of(result("bm25", 1, 0)),
                List.of(result("vector", 0, 1))
        );
        EmbeddingSearchService service = new EmbeddingSearchService(embeddingProvider, backend);
        AclFilterService.AclFilter filter = new AclFilterService.AclFilter("u1", java.util.Set.of(), null);

        float[] vector = service.embedQuery("hello");
        List<RetrievalResult> bm25 = service.bm25Search("hello", filter, 5);
        List<RetrievalResult> vectorResults = service.vectorSearch(vector, filter, 5);

        assertThat(embeddingProvider.lastText()).isEqualTo("hello");
        assertThat(bm25).extracting(RetrievalResult::chunkId).containsExactly("bm25");
        assertThat(vectorResults).extracting(RetrievalResult::chunkId).containsExactly("vector");
    }

    private static RetrievalResult result(String chunkId, double bm25, double vector) {
        return new RetrievalResult(chunkId, "d", "content", "title", "BUSINESS", "t", "1",
                "content", "/r", bm25, vector, 0, Map.of("aclScope", "PUBLIC"));
    }
}

final class FakeEmbeddingProvider implements EmbeddingProvider {
    private String lastText;

    @Override
    public int dimensions() {
        return 3;
    }

    @Override
    public float[] embed(String text) {
        lastText = text;
        return new float[]{1, 0, 0};
    }

    String lastText() {
        return lastText;
    }
}

record StaticEmbeddingProvider(float[] vector) implements EmbeddingProvider {

    @Override
    public int dimensions() {
        return vector.length;
    }

    @Override
    public float[] embed(String text) {
        return vector;
    }
}

record FakeBackend(
        List<RetrievalResult> bm25Results,
        List<RetrievalResult> vectorResults
) implements RagSearchBackend {

    @Override
    public List<RetrievalResult> bm25Search(
            String normalizedQuery,
            AclFilterService.AclFilter aclFilter,
            int limit
    ) {
        return bm25Results.stream().limit(limit).toList();
    }

    @Override
    public List<RetrievalResult> vectorSearch(
            float[] queryVector,
            AclFilterService.AclFilter aclFilter,
            int limit
    ) {
        return vectorResults.stream().limit(limit).toList();
    }
}
