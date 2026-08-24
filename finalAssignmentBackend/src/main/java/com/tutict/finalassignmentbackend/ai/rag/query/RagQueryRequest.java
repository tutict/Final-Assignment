package com.tutict.finalassignmentbackend.ai.rag.query;

/**
 * RAG query request. Only query and topK are accepted from the client.
 * userId, roles, and department are injected server-side from the authentication context.
 */
public record RagQueryRequest(
        String query,
        Integer topK
) {
}
