package com.tutict.finalassignmentcloud.ai.client.rag;

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
