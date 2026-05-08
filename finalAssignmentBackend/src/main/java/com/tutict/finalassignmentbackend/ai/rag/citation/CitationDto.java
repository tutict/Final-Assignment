package com.tutict.finalassignmentbackend.ai.rag.citation;

import java.io.Serial;
import java.io.Serializable;
import java.util.Map;

public record CitationDto(
        String chunkId,
        String documentId,
        String title,
        String route,
        String sourceTable,
        String sourceId,
        String source,
        String snippet,
        double score,
        Map<String, Object> metadata
) implements Serializable {
    @Serial
    private static final long serialVersionUID = 1L;

    public CitationDto {
        metadata = metadata == null ? Map.of() : Map.copyOf(metadata);
    }
}
