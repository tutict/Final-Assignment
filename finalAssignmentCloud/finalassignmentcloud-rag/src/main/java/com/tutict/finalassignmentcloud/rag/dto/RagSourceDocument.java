package com.tutict.finalassignmentcloud.rag.dto;

import java.util.Objects;

public record RagSourceDocument(
        String sourceType,
        String sourceTable,
        String sourceId,
        String sourceVersion,
        String title,
        String content,
        String aclScope,
        String route,
        String metadataJson,
        String sourceField
) {
    public RagSourceDocument {
        sourceType = defaultIfBlank(sourceType, "BUSINESS");
        sourceTable = requireText(sourceTable, "sourceTable");
        sourceId = requireText(sourceId, "sourceId");
        sourceVersion = defaultIfBlank(sourceVersion, "v1");
        title = defaultIfBlank(title, sourceTable + ":" + sourceId);
        content = defaultIfBlank(content, "");
        aclScope = defaultIfBlank(aclScope, "PUBLIC");
        route = defaultIfBlank(route, "");
        metadataJson = defaultIfBlank(metadataJson, "{}");
        sourceField = defaultIfBlank(sourceField, "content");
    }

    private static String requireText(String value, String name) {
        if (value == null || value.isBlank()) {
            throw new IllegalArgumentException(name + " must not be blank");
        }
        return value.trim();
    }

    private static String defaultIfBlank(String value, String fallback) {
        return value == null || value.isBlank() ? Objects.requireNonNull(fallback) : value.trim();
    }
}

