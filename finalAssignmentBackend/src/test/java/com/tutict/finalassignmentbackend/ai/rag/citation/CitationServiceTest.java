package com.tutict.finalassignmentbackend.ai.rag.citation;

import com.tutict.finalassignmentbackend.ai.rag.dto.RetrievalResult;
import org.junit.jupiter.api.Test;

import java.io.ByteArrayOutputStream;
import java.io.ObjectOutputStream;
import java.io.Serializable;
import java.util.LinkedHashMap;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

class CitationServiceTest {

    private final CitationService service = new CitationService();

    @Test
    void mapsRetrievalResultToCitationWithSourceSnippetAndScoreMetadata() {
        CitationDto citation = service.toCitation(result(Map.of("domain", "traffic")));

        assertThat(citation.chunkId()).isEqualTo("chunk-1");
        assertThat(citation.documentId()).isEqualTo("doc-1");
        assertThat(citation.title()).isEqualTo("Penalty Rules");
        assertThat(citation.route()).isEqualTo("/offense-types/42");
        assertThat(citation.sourceTable()).isEqualTo("offense_type");
        assertThat(citation.sourceId()).isEqualTo("42");
        assertThat(citation.source()).isEqualTo("offense_type:42");
        assertThat(citation.snippet()).isEqualTo("first line second line");
        assertThat(citation.score()).isEqualTo(0.87);
        assertThat(citation.metadata())
                .containsEntry("domain", "traffic")
                .containsEntry("source", "offense_type:42")
                .containsEntry("snippet", "first line second line")
                .containsEntry("score", 0.87)
                .containsEntry("sourceType", "BUSINESS")
                .containsEntry("sourceField", "description");
    }

    @Test
    void keepsCitationDtoSerializable() throws Exception {
        CitationDto citation = service.toCitation(result(Map.of("domain", "traffic")));

        assertThat(citation).isInstanceOf(Serializable.class);
        ByteArrayOutputStream bytes = new ByteArrayOutputStream();
        try (ObjectOutputStream outputStream = new ObjectOutputStream(bytes)) {
            outputStream.writeObject(citation);
        }
        assertThat(bytes.size()).isPositive();
    }

    private static RetrievalResult result(Map<String, Object> metadata) {
        Map<String, Object> values = new LinkedHashMap<>(metadata);
        return new RetrievalResult(
                "chunk-1",
                "doc-1",
                " first line\r\nsecond line ",
                "Penalty Rules",
                "BUSINESS",
                "offense_type",
                "42",
                "description",
                "/offense-types/42",
                0.25,
                0.75,
                0.87,
                values
        );
    }
}
