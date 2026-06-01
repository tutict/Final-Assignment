package com.tutict.finalassignmentcloud.ai.client.rag;

import java.util.Map;

public record RagRetrievalResult(
        String chunkId,
        String documentId,
        String content,
        String title,
        String sourceType,
        String sourceTable,
        String sourceId,
        String sourceField,
        String route,
        double bm25Score,
        double vectorScore,
        double finalScore,
        Map<String, Object> metadata
) {
    public RagRetrievalResult {
        metadata = metadata == null ? Map.of() : Map.copyOf(metadata);
    }
}
