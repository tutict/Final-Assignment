package com.tutict.finalassignmentbackend.ai.rag.query;

import java.util.List;

/**
 * Server-side-only RAG query request with ACL context derived from authentication.
 * Never constructed from client-provided data.
 */
public record ServerSideRagQueryRequest(
        String query,
        Integer topK,
        String userId,
        List<String> roles,
        String department
) {
    public ServerSideRagQueryRequest {
        roles = roles == null ? List.of() : List.copyOf(roles);
    }
}