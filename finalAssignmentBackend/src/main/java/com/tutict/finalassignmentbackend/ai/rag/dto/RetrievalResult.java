package com.tutict.finalassignmentbackend.ai.rag.dto;

import java.util.Map;

public record RetrievalResult(
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
    public RetrievalResult {
        metadata = metadata == null ? Map.of() : Map.copyOf(metadata);
    }

    public RetrievalResult withScores(double bm25Score, double vectorScore, double finalScore) {
        return new RetrievalResult(
                chunkId,
                documentId,
                content,
                title,
                sourceType,
                sourceTable,
                sourceId,
                sourceField,
                route,
                bm25Score,
                vectorScore,
                finalScore,
                metadata
        );
    }
}
