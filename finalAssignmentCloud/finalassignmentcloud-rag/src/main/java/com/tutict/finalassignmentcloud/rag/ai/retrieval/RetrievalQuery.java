package com.tutict.finalassignmentcloud.rag.ai.retrieval;

public record RetrievalQuery(
        String normalizedQuery,
        AclFilterService.AccessContext accessContext,
        int topK
) {
}

