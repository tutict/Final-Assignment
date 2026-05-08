package com.tutict.finalassignmentbackend.ai.rag.citation;

import com.tutict.finalassignmentbackend.ai.rag.dto.RetrievalResult;
import org.springframework.stereotype.Service;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;

@Service
public class CitationService {

    public CitationDto toCitation(RetrievalResult result) {
        Objects.requireNonNull(result, "result");

        String source = source(result);
        String snippet = snippet(result.content());
        double score = result.finalScore();

        return new CitationDto(
                result.chunkId(),
                result.documentId(),
                result.title(),
                result.route(),
                result.sourceTable(),
                result.sourceId(),
                source,
                snippet,
                score,
                metadata(result, source, snippet, score)
        );
    }

    public List<CitationDto> toCitations(List<RetrievalResult> results) {
        if (results == null || results.isEmpty()) {
            return List.of();
        }
        return results.stream()
                .map(this::toCitation)
                .toList();
    }

    private static Map<String, Object> metadata(
            RetrievalResult result,
            String source,
            String snippet,
            double score
    ) {
        Map<String, Object> metadata = new LinkedHashMap<>(result.metadata());
        metadata.put("source", source);
        metadata.put("snippet", snippet);
        metadata.put("score", score);
        putIfPresent(metadata, "sourceType", result.sourceType());
        putIfPresent(metadata, "sourceTable", result.sourceTable());
        putIfPresent(metadata, "sourceId", result.sourceId());
        putIfPresent(metadata, "sourceField", result.sourceField());
        return metadata;
    }

    private static String source(RetrievalResult result) {
        String explicit = metadataString(result.metadata(), "source", "citationSource");
        if (!explicit.isBlank()) {
            return explicit;
        }

        String sourceTable = clean(result.sourceTable());
        String sourceId = clean(result.sourceId());
        if (!sourceTable.isBlank() && !sourceId.isBlank()) {
            return sourceTable + ":" + sourceId;
        }
        if (!sourceTable.isBlank()) {
            return sourceTable;
        }

        String documentId = clean(result.documentId());
        if (!documentId.isBlank()) {
            return documentId;
        }
        return clean(result.chunkId());
    }

    private static String snippet(String content) {
        return clean(content).replaceAll("[\\p{Zs}\\t\\r\\n]+", " ");
    }

    private static String metadataString(Map<String, Object> metadata, String... keys) {
        for (String key : keys) {
            Object value = metadata.get(key);
            if (value != null && !value.toString().isBlank()) {
                return value.toString().trim();
            }
        }
        return "";
    }

    private static String clean(String value) {
        return value == null ? "" : value.trim();
    }

    private static void putIfPresent(Map<String, Object> metadata, String key, String value) {
        if (value != null && !value.isBlank()) {
            metadata.putIfAbsent(key, value);
        }
    }
}
