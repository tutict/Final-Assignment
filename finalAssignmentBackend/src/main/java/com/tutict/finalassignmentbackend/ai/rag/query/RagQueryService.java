package com.tutict.finalassignmentbackend.ai.rag.query;

import com.tutict.finalassignmentbackend.ai.rag.config.RagRetrievalProperties;
import com.tutict.finalassignmentbackend.ai.rag.dto.RetrievalResult;
import com.tutict.finalassignmentbackend.ai.rag.retrieval.AclFilterService;
import com.tutict.finalassignmentbackend.ai.rag.retrieval.HybridRetriever;
import com.tutict.finalassignmentbackend.ai.rag.retrieval.RetrievalQuery;
import com.tutict.finalassignmentbackend.config.security.SecurityRoleUtils;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
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

    public List<RetrievalResult> query(ServerSideRagQueryRequest request) {
        String normalizedQuery = normalizeQuery(request == null ? null : request.query());
        if (!properties.isEnabled() || normalizedQuery.isBlank()) {
            return List.of();
        }
        int topK = request.topK() == null ? properties.getTopK() : Math.max(1, Math.min(request.topK(), 50));
        RetrievalQuery query = new RetrievalQuery(
                normalizedQuery,
                aclFilterService.context(request.userId(), request.roles(), request.department()),
                topK
        );
        return hybridRetriever.retrieve(query);
    }

    /**
     * @deprecated Use {@link #query(ServerSideRagQueryRequest)} instead.
     * This method constructs ACL context from the current security context.
     */
    @Deprecated
    public List<RetrievalResult> query(RagQueryRequest request) {
        String normalizedQuery = normalizeQuery(request == null ? null : request.query());
        if (!properties.isEnabled() || normalizedQuery.isBlank()) {
            return List.of();
        }
        int topK = request.topK() == null ? properties.getTopK() : Math.max(1, Math.min(request.topK(), 50));

        // Derive ACL from security context, never from client-provided request fields
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        String userId = null;
        List<String> roles = List.of();
        String department = null;
        if (authentication != null && authentication.isAuthenticated() && !"anonymousUser".equals(authentication.getPrincipal())) {
            userId = authentication.getName();
            roles = authentication.getAuthorities().stream()
                    .map(a -> SecurityRoleUtils.normalizeRoleCode(a.getAuthority()))
                    .filter(role -> !role.isBlank())
                    .toList();
            for (String role : roles) {
                if ("SUPER_ADMIN".equals(role) || "ADMIN".equals(role)) {
                    department = "ALL";
                    break;
                } else if ("TRAFFIC_POLICE".equals(role) || "FINANCE".equals(role) || "APPEAL_REVIEWER".equals(role)) {
                    department = "DEPARTMENT";
                    break;
                }
            }
        }

        RetrievalQuery query = new RetrievalQuery(
                normalizedQuery,
                aclFilterService.context(userId, roles, department),
                topK
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
