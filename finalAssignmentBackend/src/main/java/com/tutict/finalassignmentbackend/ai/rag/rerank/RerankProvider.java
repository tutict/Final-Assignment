package com.tutict.finalassignmentbackend.ai.rag.rerank;

import com.tutict.finalassignmentbackend.ai.rag.dto.RetrievalResult;

import java.util.List;

public interface RerankProvider {

    List<RetrievalResult> rerank(String query, List<RetrievalResult> results);
}
