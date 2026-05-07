package com.tutict.finalassignmentbackend.ai.rag.retrieval;

public record RetrievalQuery(
        String normalizedQuery,
        AclFilterService.AccessContext accessContext,
        int topK
) {
}
