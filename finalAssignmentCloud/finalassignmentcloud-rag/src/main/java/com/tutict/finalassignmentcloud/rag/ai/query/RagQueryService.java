package com.tutict.finalassignmentcloud.rag.ai.query;

import com.tutict.finalassignmentcloud.rag.ai.config.RagRetrievalProperties;
import com.tutict.finalassignmentcloud.rag.ai.dto.RetrievalResult;
import com.tutict.finalassignmentcloud.rag.ai.retrieval.AclFilterService;
import com.tutict.finalassignmentcloud.rag.ai.retrieval.HybridRetriever;
import com.tutict.finalassignmentcloud.rag.ai.retrieval.RetrievalQuery;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Service;

import java.text.Normalizer;
import java.util.List;

@Service
@ConditionalOnProperty(prefix = "rag.retrieval", name = "enabled", havingValue = "true")
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

