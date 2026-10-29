package finalassignmentbackend.rag.service;

import finalassignmentbackend.mapper.RagChunkMapper;
import finalassignmentbackend.mapper.RagDocumentMapper;
import finalassignmentbackend.rag.access.RagAccessContext;
import finalassignmentbackend.rag.access.RagAclPolicy;
import finalassignmentbackend.rag.config.RagProperties;
import finalassignmentbackend.rag.embedding.RagEmbeddingProvider;
import finalassignmentbackend.rag.entity.RagChunk;
import finalassignmentbackend.rag.entity.RagDocument;
import finalassignmentbackend.rag.retrieval.HybridRetriever;
import finalassignmentbackend.rag.retrieval.RagSearchBackend;
import finalassignmentbackend.rag.retrieval.RagSearchHit;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.lang.reflect.Proxy;
import java.util.ArrayList;
import java.util.List;
import java.util.Set;
import java.util.concurrent.atomic.AtomicInteger;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

class RagQueryServiceTest {

    private RagProperties properties;
    private RagQueryService service;
    private FakeRetriever retriever;
    private FakeCandidateStore candidateStore;
    private List<RagDocument> documents;
    private List<RagChunk> chunks;
    private AtomicInteger documentQueries;
    private AtomicInteger chunkQueries;

    @BeforeEach
    void setUp() {
        properties = new RagProperties();
        properties.setEnabled(true);
        properties.setRetrievalEnabled(true);
        properties.setElasticsearchEnabled(true);
        properties.setMysqlFallbackEnabled(true);
        retriever = new FakeRetriever();
        candidateStore = new FakeCandidateStore();
        documents = new ArrayList<>();
        chunks = new ArrayList<>();
        documentQueries = new AtomicInteger();
        chunkQueries = new AtomicInteger();
        service = new RagQueryService();
        service.properties = properties;
        service.hybridRetriever = retriever;
        service.candidateStore = candidateStore;
        service.documentMapper = documentMapper(documents, documentQueries);
        service.chunkMapper = chunkMapper(chunks, chunkQueries);
    }

    @Test
    void elasticsearchResultsAreReturnedWithTheirScores() {
        retriever.hits = List.of(hit("chunk-1"));
        candidateStore.candidates = List.of(candidate("chunk-1", 1.25));

        List<RagQueryService.RetrievedChunk> results = service.retrieve("罚款", driver(), 5);

        assertEquals(1, results.size());
        assertEquals("chunk-1", results.get(0).chunkId());
        assertEquals(1.25, results.get(0).finalScore());
    }

    @Test
    void emptyElasticsearchResultDoesNotFallBackToLexicalSearch() {
        retriever.hits = List.of();
        documents.add(document("doc-1", "PUBLIC", "{}"));

        List<RagQueryService.RetrievedChunk> results = service.retrieve("罚款", driver(), 5);

        assertTrue(results.isEmpty());
        assertEquals(0, documentQueries.get(), "the lexical path must not run when Elasticsearch answered");
        assertEquals(0, chunkQueries.get(), "the lexical path must not run when Elasticsearch answered");
    }

    @Test
    void elasticsearchFailureFallsBackToMySqlLexicalSearch() {
        retriever.failure = new IllegalStateException("elasticsearch unreachable");
        documents.add(document("doc-1", "PUBLIC", "{}"));
        chunks.add(chunk("chunk-1", "doc-1", "罚款应当在十五日内缴纳。"));

        List<RagQueryService.RetrievedChunk> results = service.retrieve("罚款缴纳", driver(), 5);

        assertEquals(1, results.size());
        assertEquals("chunk-1", results.get(0).chunkId());
    }

    @Test
    void fallbackCanBeDisabled() {
        properties.setMysqlFallbackEnabled(false);
        retriever.failure = new IllegalStateException("elasticsearch unreachable");

        try {
            service.retrieve("罚款", driver(), 5);
        } catch (IllegalStateException expected) {
            return;
        }
        throw new AssertionError("the retrieval failure must propagate when the fallback is disabled");
    }

    @Test
    void lexicalFallbackAppliesTheStrictAcl() {
        properties.setElasticsearchEnabled(false);
        documents.add(document("doc-1", "ROLE", "{\"aclRoles\":[\"SUPER_ADMIN\"]}"));
        chunks.add(chunk("chunk-1", "doc-1", "操作日志审查"));

        assertTrue(service.retrieve("操作日志", driver(), 5).isEmpty());
    }

    @Test
    void allowedDocumentsFollowTheStrictAcl() {
        RagDocument publicDoc = document("doc-1", "PUBLIC", "{}");
        RagDocument roleDoc = document("doc-2", "ROLE", "{\"aclRoles\":[\"SUPER_ADMIN\"]}");
        RagDocument userDoc = document("doc-3", "USER", "{\"userIds\":[\"driver-1001\"]}");
        RagDocument departmentDoc = document("doc-4", "DEPARTMENT", "{\"aclDepartments\":[\"finance\"]}");
        List<RagDocument> docs = List.of(publicDoc, roleDoc, userDoc, departmentDoc);

        assertEquals(List.of("doc-1"), ids(RagQueryService.selectAllowedDocuments(docs, driver())));
        assertEquals(List.of("doc-1", "doc-2"),
                ids(RagQueryService.selectAllowedDocuments(docs, RagAccessContext.of("admin-1", Set.of("SUPER_ADMIN")))));
        assertEquals(List.of("doc-1", "doc-3"),
                ids(RagQueryService.selectAllowedDocuments(docs, RagAccessContext.of("driver-1001", Set.of("USER")))));
    }

    @Test
    void allowedDocumentsDropNonKnowledgeDocuments() {
        RagDocument business = document("doc-1", "PUBLIC", "{}");
        business.setSourceType("BUSINESS");
        RagDocument manual = document("doc-2", "PUBLIC", "{}");

        assertEquals(List.of("doc-2"), ids(RagQueryService.selectAllowedDocuments(List.of(business, manual), driver())));
    }

    @Test
    void topKIsCappedAtFifty() {
        assertEquals(50, RagQueryService.MAX_TOP_K);
    }

    @Test
    void bigramScoringFindsParaphrasedChineseQuestion() {
        double paraphrase = RagQueryService.score(
                "罚款最晚需要在多长时间内缴纳",
                "缴款期限",
                "当事人应当在收到处罚决定书之日起十五日内到指定银行缴纳罚款。"
        );
        double unrelated = RagQueryService.score(
                "罚款最晚需要在多长时间内缴纳",
                "车辆过户",
                "办理过户需要提交机动车登记证书、行驶证和双方身份证明。"
        );

        assertTrue(paraphrase > 0, "paraphrased question must still retrieve the passage");
        assertTrue(paraphrase > unrelated, "relevant passage must outrank an unrelated one");
        assertEquals(0, RagQueryService.score("   ", "缴款期限", "罚款应在十五日内缴纳"));
    }

    @Test
    void wholePhraseMatchOutranksBigramOnlyMatch() {
        double exact = RagQueryService.score("罚款缴纳", "罚款缴纳流程", "罚款缴纳可以线上办理。");
        double partial = RagQueryService.score("罚款缴纳", "车辆年检", "年检时需要先处理罚款，缴纳后即可预约。");

        assertTrue(exact > partial, "whole-phrase match must outrank bigram overlap");
    }

    @Test
    void resultCarriesSourceIdFromDocument() {
        RagChunk chunk = new RagChunk();
        chunk.setId("chunk-1");
        chunk.setDocumentId("doc-1");
        chunk.setContent("罚款应在十五日内缴纳。");
        RagDocument document = document("doc-1", "PUBLIC", "{}");
        document.setSourceId("seed-a01-chunk-1");
        document.setTitle("缴款期限");
        document.setSourceType("MANUAL");
        document.setRoute("/userFineListPage");

        RagQueryService.RetrievedChunk result = RagQueryService.toResult(chunk, document, 1.5);

        assertEquals("chunk-1", result.chunkId());
        assertEquals("doc-1", result.documentId());
        assertEquals("seed-a01-chunk-1", result.sourceId());
        assertEquals("罚款应在十五日内缴纳。", result.content());
        assertEquals("/userFineListPage", result.route());
        assertEquals(1.5, result.finalScore());
    }

    private static RagAccessContext driver() {
        return RagAccessContext.of("driver-1", Set.of("USER"));
    }

    private static List<String> ids(List<RagDocument> docs) {
        return docs.stream().map(RagDocument::getId).toList();
    }

    private static RagSearchHit hit(String chunkId) {
        return new RagSearchHit(chunkId, "doc-1", "罚款应当在十五日内缴纳。", "缴款期限",
                "MANUAL", "manual_rag_document", "source-1", "content", "/userFineListPage",
                1.0, 0, 1.0, new RagAclPolicy.DocumentAcl("PUBLIC", Set.of(), Set.of(), Set.of()));
    }

    private static MySqlRagCandidateStore.Candidate candidate(String chunkId, double score) {
        return new MySqlRagCandidateStore.Candidate(chunkId, "doc-1", "source-1",
                "罚款应当在十五日内缴纳。", "缴款期限", "MANUAL", "/userFineListPage", score);
    }

    private static RagDocument document(String id, String aclScope, String metadataJson) {
        RagDocument document = new RagDocument();
        document.setId(id);
        document.setSourceType("MANUAL");
        document.setStatus("READY");
        document.setTitle("缴款期限");
        document.setRoute("/userFineListPage");
        document.setAclScope(aclScope);
        document.setMetadataJson(metadataJson);
        return document;
    }

    private static RagChunk chunk(String id, String documentId, String content) {
        RagChunk chunk = new RagChunk();
        chunk.setId(id);
        chunk.setDocumentId(documentId);
        chunk.setContent(content);
        chunk.setStatus("EMBEDDED");
        return chunk;
    }

    private static RagDocumentMapper documentMapper(List<RagDocument> rows, AtomicInteger queries) {
        return (RagDocumentMapper) Proxy.newProxyInstance(
                RagDocumentMapper.class.getClassLoader(),
                new Class<?>[]{RagDocumentMapper.class},
                (proxy, method, args) -> {
                    if ("selectList".equals(method.getName())) {
                        queries.incrementAndGet();
                        return rows;
                    }
                    if ("selectById".equals(method.getName())) {
                        String id = (String) args[0];
                        return rows.stream().filter(row -> id.equals(row.getId())).findFirst().orElse(null);
                    }
                    return null;
                });
    }

    private static RagChunkMapper chunkMapper(List<RagChunk> rows, AtomicInteger queries) {
        return (RagChunkMapper) Proxy.newProxyInstance(
                RagChunkMapper.class.getClassLoader(),
                new Class<?>[]{RagChunkMapper.class},
                (proxy, method, args) -> {
                    if ("selectList".equals(method.getName())) {
                        queries.incrementAndGet();
                        return rows;
                    }
                    if ("selectById".equals(method.getName())) {
                        String id = (String) args[0];
                        return rows.stream().filter(row -> id.equals(row.getId())).findFirst().orElse(null);
                    }
                    return null;
                });
    }

    private static final class FakeRetriever extends HybridRetriever {

        private List<RagSearchHit> hits = List.of();
        private RuntimeException failure;

        private FakeRetriever() {
            super(new NoopProvider(), new NoopBackend(), new RagProperties());
        }

        @Override
        public List<RagSearchHit> retrieve(String query, RagAccessContext context, int limit) {
            if (failure != null) {
                throw failure;
            }
            return hits;
        }
    }

    private static final class FakeCandidateStore extends MySqlRagCandidateStore {

        private List<MySqlRagCandidateStore.Candidate> candidates = List.of();

        @Override
        public List<MySqlRagCandidateStore.Candidate> resolve(List<RagSearchHit> hits, RagAccessContext context) {
            return candidates;
        }
    }

    private static final class NoopProvider implements RagEmbeddingProvider {

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
            return new float[]{0.1f};
        }
    }

    private static final class NoopBackend implements RagSearchBackend {

        @Override
        public List<RagSearchHit> bm25Search(String query, RagAccessContext context, int limit) {
            return List.of();
        }

        @Override
        public List<RagSearchHit> vectorSearch(float[] queryVector, RagAccessContext context, int limit) {
            return List.of();
        }
    }
}
