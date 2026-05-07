package com.tutict.finalassignmentbackend.ai.rag.query;

import java.util.List;

public record RagQueryRequest(
        String query,
        Integer topK,
        String userId,
        List<String> roles,
        String department
) {
    public RagQueryRequest {
        roles = roles == null ? List.of() : List.copyOf(roles);
    }
}
