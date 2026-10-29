package finalassignmentbackend.rag.retrieval;

import finalassignmentbackend.rag.access.RagAccessContext;
import finalassignmentbackend.rag.access.RagAclPolicy;
import finalassignmentbackend.rag.config.RagProperties;
import finalassignmentbackend.rag.embedding.RagEmbeddingProvider;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.util.List;
import java.util.Set;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

class HybridRetrieverTest {

    private RagProperties properties;
    private FakeBackend backend;
    private FakeProvider provider;
    private HybridRetriever retriever;

    @BeforeEach
    void setUp() {
        properties = new RagProperties();
        properties.setEmbeddingEnabled(true);
        properties.setBm25Weight(0.8);
        properties.setVectorWeight(0.2);
        properties.setMinScore(0.2);
        properties.setCandidateMultiplier(3);
        properties.setRrfRankConstant(60);
        properties.setRerankEnabled(true);
        properties.setRerankLexicalWeight(0.15);
        backend = new FakeBackend();
        provider = new FakeProvider();
        retriever = new HybridRetriever(provider, backend, properties);
    }

    @Test
    void chunkFoundByBothChannelsOutranksSingleChannelHit() {
        backend.bm25 = List.of(hit("chunk-both", "PUBLIC"), hit("chunk-bm25", "PUBLIC"));
        backend.vector = List.of(hit("chunk-both", "PUBLIC"));

        List<RagSearchHit> hits = retriever.retrieve("罚款", driver(), 5);

        assertEquals("chunk-both", hits.get(0).chunkId());
    }

    @Test
    void duplicateChunkIdsAreFusedIntoOneResult() {
        backend.bm25 = List.of(hit("chunk-1", "PUBLIC"));
        backend.vector = List.of(hit("chunk-1", "PUBLIC"));

        List<RagSearchHit> hits = retriever.retrieve("罚款", driver(), 5);

        double expected = 100 * 0.8 / 61 + 100 * 0.2 / 61;
        assertEquals(1, hits.size());
        assertEquals(expected, hits.get(0).finalScore(), 1e-9);
    }

    @Test
    void hitsBelowMinimumScoreAreDropped() {
        properties.setBm25Weight(0.0);
        properties.setVectorWeight(0.0);
        backend.bm25 = List.of(hit("chunk-1", "PUBLIC"));

        assertTrue(retriever.retrieve("罚款", driver(), 5).isEmpty());
    }

    @Test
    void aclFilterRunsAfterFusion() {
        backend.bm25 = List.of(hit("chunk-secret", "ROLE", "SUPER_ADMIN"));

        assertTrue(retriever.retrieve("审计", driver(), 5).isEmpty());
    }

    @Test
    void vectorFailureDegradesToBm25Only() {
        backend.bm25 = List.of(hit("chunk-1", "PUBLIC"));
        provider.failure = new IllegalStateException("ollama unreachable");

        List<RagSearchHit> hits = retriever.retrieve("罚款", driver(), 5);

        assertEquals(1, hits.size());
        assertEquals("chunk-1", hits.get(0).chunkId());
    }

    @Test
    void disabledEmbeddingSkipsTheVectorChannel() {
        properties.setEmbeddingEnabled(false);
        backend.bm25 = List.of(hit("chunk-1", "PUBLIC"));

        retriever.retrieve("罚款", driver(), 5);

        assertEquals(0, provider.calls);
        assertEquals(0, backend.vectorRequests);
    }

    @Test
    void candidateLimitIsMultipliedByTheCandidateMultiplier() {
        backend.bm25 = List.of(hit("chunk-1", "PUBLIC"));

        retriever.retrieve("罚款", driver(), 5);

        assertEquals(15, backend.bm25Limit);
        assertEquals(15, backend.vectorLimit);
    }

    @Test
    void lexicalRerankPromotesTheBetterMatchingTitle() {
        backend.bm25 = List.of(
                new RagSearchHit("chunk-weak", "doc-1", "年检需要先处理违章记录。", "车辆年检说明",
                        "MANUAL", "manual_rag_document", "source-1", "content", "/userFineListPage",
                        1.0, 0, 1.0, new RagAclPolicy.DocumentAcl("PUBLIC", Set.of(), Set.of(), Set.of())),
                new RagSearchHit("chunk-strong", "doc-2", "罚款缴纳流程说明。", "罚款缴纳流程",
                        "MANUAL", "manual_rag_document", "source-2", "content", "/userFineListPage",
                        1.0, 0, 1.0, new RagAclPolicy.DocumentAcl("PUBLIC", Set.of(), Set.of(), Set.of()))
        );

        List<RagSearchHit> hits = retriever.retrieve("罚款缴纳", driver(), 5);

        assertEquals("chunk-strong", hits.get(0).chunkId());
    }

    private static RagAccessContext driver() {
        return RagAccessContext.of("driver-1", Set.of("USER"));
    }

    private static RagSearchHit hit(String chunkId, String scope, String... roles) {
        return new RagSearchHit(chunkId, "doc-1", "罚款应当在十五日内缴纳。", "缴款期限",
                "MANUAL", "manual_rag_document", "source-1", "content", "/userFineListPage",
                1.0, 0, 1.0,
                new RagAclPolicy.DocumentAcl(scope, Set.of(roles), Set.of(), Set.of()));
    }

    private static final class FakeBackend implements RagSearchBackend {

        private List<RagSearchHit> bm25 = List.of();
        private List<RagSearchHit> vector = List.of();
        private int bm25Limit;
        private int vectorLimit;
        private int vectorRequests;

        @Override
        public List<RagSearchHit> bm25Search(String query, RagAccessContext context, int limit) {
            this.bm25Limit = limit;
            return bm25;
        }

        @Override
        public List<RagSearchHit> vectorSearch(float[] queryVector, RagAccessContext context, int limit) {
            this.vectorRequests++;
            this.vectorLimit = limit;
            return vector;
        }
    }

    private static final class FakeProvider implements RagEmbeddingProvider {

        private RuntimeException failure;
        private int calls;

        @Override
        public String providerName() {
            return "ollama";
        }

        @Override
        public String modelName() {
            return "nomic-embed-text";
        }

        @Override
        public int dimensions() {
            return 768;
        }

        @Override
        public float[] embed(String text) {
            calls++;
            if (failure != null) {
                throw failure;
            }
            return new float[]{0.1f, 0.2f};
        }
    }
}
