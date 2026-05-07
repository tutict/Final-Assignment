package com.tutict.finalassignmentbackend.ai.rag.citation;

import java.util.Map;

public record CitationDto(
        String chunkId,
        String documentId,
        String title,
        String route,
        String sourceTable,
        String sourceId,
        Map<String, Object> metadata
) {
    public CitationDto {
        metadata = metadata == null ? Map.of() : Map.copyOf(metadata);
    }
}
