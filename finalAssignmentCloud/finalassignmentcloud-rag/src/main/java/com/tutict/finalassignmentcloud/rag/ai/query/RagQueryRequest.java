package com.tutict.finalassignmentcloud.rag.ai.query;

/**
 * Client-facing RAG query request. ACL fields are NOT accepted from the client;
 * they are resolved server-side from the SecurityContextHolder by the controller.
 */
public record RagQueryRequest(
        String query,
        Integer topK
) {
}