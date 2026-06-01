package com.tutict.finalassignmentcloud.rag.ai.rerank;

import com.tutict.finalassignmentcloud.rag.ai.dto.RetrievalResult;

import java.util.List;

public interface RerankProvider {

    List<RetrievalResult> rerank(String query, List<RetrievalResult> results);
}

