package finalassignmentbackend.rag.service;

import finalassignmentbackend.mapper.RagChunkMapper;
import finalassignmentbackend.mapper.RagDocumentMapper;
import finalassignmentbackend.rag.access.RagAccessContext;
import finalassignmentbackend.rag.access.RagAclPolicy;
import finalassignmentbackend.rag.entity.RagChunk;
import finalassignmentbackend.rag.entity.RagDocument;
import finalassignmentbackend.rag.retrieval.RagSearchHit;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.lang.reflect.Proxy;
import java.util.ArrayList;
import java.util.List;
import java.util.Set;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * ES 命中回读 MySQL 后的严格收敛。
 *
 * <p>ES 侧只做粗过滤，真正的可见性以库里的行为准：任何一条不满足「已嵌入 / 文档就绪 /
 * 知识库来源 / ACL 放行」的分块都不允许进入结果。
 */
class MySqlRagCandidateStoreTest {

    private MySqlRagCandidateStore store;
    private List<RagDocument> documents;
    private List<RagChunk> chunks;

    @BeforeEach
    void setUp() {
        documents = new ArrayList<>();
        chunks = new ArrayList<>();
        store = new MySqlRagCandidateStore();
        store.chunkMapper = chunkMapper(chunks);
        store.documentMapper = documentMapper(documents);
    }

    @Test
    void embeddedAndAllowedChunkIsReturnedWithItsScore() {
        documents.add(document("doc-1", "PUBLIC", "{}"));
        chunks.add(chunk("chunk-1", "doc-1", "罚款应当在十五日内缴纳。"));

        List<MySqlRagCandidateStore.Candidate> candidates = store.resolve(List.of(hit("chunk-1", 1.75)), driver());

        assertEquals(1, candidates.size());
        assertEquals("chunk-1", candidates.get(0).chunkId());
        assertEquals("doc-1", candidates.get(0).documentId());
        assertEquals("source-1", candidates.get(0).sourceId());
        assertEquals(1.75, candidates.get(0).finalScore());
    }

    @Test
    void staleElasticsearchDocumentWithoutAMatchingRowIsDropped() {
        List<MySqlRagCandidateStore.Candidate> candidates = store.resolve(List.of(hit("chunk-gone", 1.0)), driver());

        assertTrue(candidates.isEmpty());
    }

    @Test
    void chunkThatIsNotEmbeddedYetIsDropped() {
        documents.add(document("doc-1", "PUBLIC", "{}"));
        RagChunk chunk = chunk("chunk-1", "doc-1", "罚款应当在十五日内缴纳。");
        chunk.setStatus("PENDING");
        chunks.add(chunk);

        assertTrue(store.resolve(List.of(hit("chunk-1", 1.0)), driver()).isEmpty());
    }

    @Test
    void documentThatIsNotReadyIsDropped() {
        RagDocument document = document("doc-1", "PUBLIC", "{}");
        document.setStatus("PENDING");
        documents.add(document);
        chunks.add(chunk("chunk-1", "doc-1", "罚款应当在十五日内缴纳。"));

        assertTrue(store.resolve(List.of(hit("chunk-1", 1.0)), driver()).isEmpty());
    }

    @Test
    void businessDocumentIsNotRetrievable() {
        RagDocument document = document("doc-1", "PUBLIC", "{}");
        document.setSourceType("BUSINESS");
        documents.add(document);
        chunks.add(chunk("chunk-1", "doc-1", "业务数据"));

        assertTrue(store.resolve(List.of(hit("chunk-1", 1.0)), driver()).isEmpty());
    }

    @Test
    void aclDeniedDocumentIsDropped() {
        documents.add(document("doc-1", "ROLE", "{\"aclRoles\":[\"SUPER_ADMIN\"]}"));
        chunks.add(chunk("chunk-1", "doc-1", "操作日志审查"));

        assertTrue(store.resolve(List.of(hit("chunk-1", 1.0)), driver()).isEmpty());
    }

    @Test
    void aclGrantedDocumentIsKept() {
        documents.add(document("doc-1", "ROLE", "{\"aclRoles\":[\"SUPER_ADMIN\"]}"));
        chunks.add(chunk("chunk-1", "doc-1", "操作日志审查"));

        List<MySqlRagCandidateStore.Candidate> candidates = store.resolve(
                List.of(hit("chunk-1", 1.0)), RagAccessContext.of("admin-1", Set.of("SUPER_ADMIN")));

        assertEquals(1, candidates.size());
    }

    @Test
    void duplicateHitsAreCollapsedIntoOneCandidate() {
        documents.add(document("doc-1", "PUBLIC", "{}"));
        chunks.add(chunk("chunk-1", "doc-1", "罚款应当在十五日内缴纳。"));

        List<MySqlRagCandidateStore.Candidate> candidates = store.resolve(
                List.of(hit("chunk-1", 1.5), hit("chunk-1", 1.5)), driver());

        assertEquals(1, candidates.size());
        assertEquals(1.5, candidates.get(0).finalScore());
    }

    @Test
    void emptyHitListReturnsNothing() {
        assertTrue(store.resolve(List.of(), driver()).isEmpty());
        assertTrue(store.resolve(null, driver()).isEmpty());
    }

    @Test
    void hitsWithoutChunkIdAreIgnored() {
        assertTrue(store.resolve(List.of(hit(null, 1.0), hit("  ", 1.0)), driver()).isEmpty());
    }

    private static RagAccessContext driver() {
        return RagAccessContext.of("driver-1", Set.of("USER"));
    }

    private static RagSearchHit hit(String chunkId, double score) {
        return new RagSearchHit(chunkId, "doc-1", "罚款应当在十五日内缴纳。", "缴款期限",
                "MANUAL", "manual_rag_document", "source-1", "content", "/userFineListPage",
                1.0, 0, score, new RagAclPolicy.DocumentAcl("PUBLIC", Set.of(), Set.of(), Set.of()));
    }

    private static RagDocument document(String id, String aclScope, String metadataJson) {
        RagDocument document = new RagDocument();
        document.setId(id);
        document.setSourceType("MANUAL");
        document.setStatus("READY");
        document.setTitle("缴款期限");
        document.setSourceId("source-1");
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

    private static RagDocumentMapper documentMapper(List<RagDocument> rows) {
        return (RagDocumentMapper) Proxy.newProxyInstance(
                RagDocumentMapper.class.getClassLoader(),
                new Class<?>[]{RagDocumentMapper.class},
                (proxy, method, args) -> "selectList".equals(method.getName()) ? rows : null);
    }

    private static RagChunkMapper chunkMapper(List<RagChunk> rows) {
        return (RagChunkMapper) Proxy.newProxyInstance(
                RagChunkMapper.class.getClassLoader(),
                new Class<?>[]{RagChunkMapper.class},
                (proxy, method, args) -> "selectList".equals(method.getName()) ? rows : null);
    }
}
