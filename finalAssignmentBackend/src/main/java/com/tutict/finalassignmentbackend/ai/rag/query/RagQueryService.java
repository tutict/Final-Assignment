package com.tutict.finalassignmentbackend.ai.rag.query;

import com.tutict.finalassignmentbackend.ai.rag.config.RagRetrievalProperties;
import com.tutict.finalassignmentbackend.ai.rag.dto.RetrievalResult;
import com.tutict.finalassignmentbackend.ai.rag.retrieval.AclFilterService;
import com.tutict.finalassignmentbackend.ai.rag.retrieval.HybridRetriever;
import com.tutict.finalassignmentbackend.ai.rag.retrieval.RetrievalQuery;
import org.springframework.stereotype.Service;

import java.text.Normalizer;
import java.util.List;

@Service
public class RagQueryService {

    private final HybridRetriever hybridRetriever;
    private final AclFilterService aclFilterService;
    private final RagRetrievalProperties properties;

    public RagQueryService(
            HybridRetriever hybridRetriever,
            AclFilterService aclFilterService,
            RagRetrievalProperties properties
    ) {
        this.hybridRetriever = hybridRetriever;
        this.aclFilterService = aclFilterService;
        this.properties = properties;
    }

    public List<RetrievalResult> query(RagQueryRequest request) {
        String normalizedQuery = normalizeQuery(request == null ? null : request.query());
        if (!properties.isEnabled() || normalizedQuery.isBlank()) {
            return List.of();
        }
        int topK = request.topK() == null ? properties.getTopK() : request.topK();
        RetrievalQuery query = new RetrievalQuery(
                normalizedQuery,
                aclFilterService.context(request.userId(), request.roles(), request.department()),
                Math.max(1, topK)
        );
        return hybridRetriever.retrieve(query);
    }

    static String normalizeQuery(String query) {
        if (query == null) {
            return "";
        }
        return Normalizer.normalize(query, Normalizer.Form.NFKC)
                .replaceAll("[\\p{Zs}\\t\\r\\n]+", " ")
                .trim();
    }
}
