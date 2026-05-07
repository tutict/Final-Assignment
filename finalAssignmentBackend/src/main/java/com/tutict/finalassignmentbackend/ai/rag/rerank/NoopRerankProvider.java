package com.tutict.finalassignmentbackend.ai.rag.rerank;

import com.tutict.finalassignmentbackend.ai.rag.dto.RetrievalResult;
import org.springframework.stereotype.Component;

import java.util.List;

@Component
public class NoopRerankProvider {

    public List<RetrievalResult> rerank(String query, List<RetrievalResult> results) {
        return results;
    }
}
