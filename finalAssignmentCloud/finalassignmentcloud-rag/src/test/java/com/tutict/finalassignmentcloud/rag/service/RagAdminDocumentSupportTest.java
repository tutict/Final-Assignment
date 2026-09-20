package com.tutict.finalassignmentcloud.rag.service;

import com.tutict.finalassignmentcloud.rag.entity.RagChunk;
import com.tutict.finalassignmentcloud.rag.entity.RagDocument;
import org.junit.jupiter.api.Test;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

class RagAdminDocumentSupportTest {

    @Test
    void stitchesOverlappingChunksInOrder() {
        RagChunk first = new RagChunk();
        first.setChunkNo(1);
        first.setContent("abcdef");
        RagChunk second = new RagChunk();
        second.setChunkNo(2);
        second.setContent("defghi");
        assertThat(RagAdminDocumentSupport.stitchContent(List.of(first, second))).isEqualTo("abcdefghi");
    }

    @Test
    void userPreviewCannotSeeRoleScopedKnowledge() {
        assertThat(RagAdminDocumentSupport.previewAllows("USER", "ROLE")).isFalse();
        assertThat(RagAdminDocumentSupport.previewAllows("ADMIN", "ROLE")).isTrue();
        assertThat(RagAdminDocumentSupport.previewAllows("USER", "PUBLIC")).isTrue();
        assertThat(RagAdminDocumentSupport.previewAllows("SUPER_ADMIN", "USER")).isTrue();
    }

    @Test
    void businessBackfillIsNotKnowledge() {
        RagDocument business = new RagDocument();
        business.setSourceType("BUSINESS");
        RagDocument manual = new RagDocument();
        manual.setSourceType("MANUAL");
        RagDocument upload = new RagDocument();
        upload.setSourceType("UPLOAD");
        assertThat(RagAdminDocumentSupport.isKnowledgeDocument(business)).isFalse();
        assertThat(RagAdminDocumentSupport.isKnowledgeDocument(manual)).isTrue();
        assertThat(RagAdminDocumentSupport.isKnowledgeDocument(upload)).isTrue();
    }
}
