package finalassignmentbackend.rag.service;

import finalassignmentbackend.rag.entity.RagChunk;
import finalassignmentbackend.rag.entity.RagDocument;
import org.junit.jupiter.api.Test;

import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

class RagQueryServiceTest {

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
    void aclFilterFollowsPreviewRules() {
        RagDocument publicDoc = document("doc-1", "PUBLIC");
        RagDocument roleDoc = document("doc-2", "ROLE");
        RagDocument userDoc = document("doc-3", "USER");
        RagDocument departmentDoc = document("doc-4", "DEPARTMENT");
        List<RagDocument> docs = List.of(publicDoc, roleDoc, userDoc, departmentDoc);

        assertEquals(List.of("doc-1", "doc-3"), ids(RagQueryService.selectAllowedDocuments(docs, "USER")));
        assertEquals(List.of("doc-1", "doc-3"), ids(RagQueryService.selectAllowedDocuments(docs, "DRIVER")));
        assertEquals(List.of("doc-1", "doc-2", "doc-4"), ids(RagQueryService.selectAllowedDocuments(docs, "ADMIN")));
        assertEquals(List.of("doc-1", "doc-2", "doc-3", "doc-4"), ids(RagQueryService.selectAllowedDocuments(docs, "SUPER_ADMIN")));
    }

    @Test
    void aclFilterDropsNonKnowledgeDocuments() {
        RagDocument business = document("doc-1", "PUBLIC");
        business.setSourceType("BUSINESS");
        RagDocument manual = document("doc-2", "PUBLIC");

        assertEquals(List.of("doc-2"), ids(RagQueryService.selectAllowedDocuments(List.of(business, manual), "ADMIN")));
    }

    @Test
    void resultCarriesSourceIdFromDocument() {
        RagChunk chunk = new RagChunk();
        chunk.setId("chunk-1");
        chunk.setDocumentId("doc-1");
        chunk.setContent("罚款应在十五日内缴纳。");
        RagDocument document = document("doc-1", "PUBLIC");
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

    private static List<String> ids(List<RagDocument> docs) {
        return docs.stream().map(RagDocument::getId).toList();
    }

    private static RagDocument document(String id, String aclScope) {
        RagDocument document = new RagDocument();
        document.setId(id);
        document.setSourceType("MANUAL");
        document.setAclScope(aclScope);
        return document;
    }
}
