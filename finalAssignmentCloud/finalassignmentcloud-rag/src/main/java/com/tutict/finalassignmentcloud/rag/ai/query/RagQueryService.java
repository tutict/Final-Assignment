package com.tutict.finalassignmentcloud.rag.ai.query;

import com.tutict.finalassignmentcloud.config.security.SecurityRoleUtils;
import com.tutict.finalassignmentcloud.rag.ai.config.RagRetrievalProperties;
import com.tutict.finalassignmentcloud.rag.ai.dto.RetrievalResult;
import com.tutict.finalassignmentcloud.rag.ai.retrieval.AclFilterService;
import com.tutict.finalassignmentcloud.rag.ai.retrieval.HybridRetriever;
import com.tutict.finalassignmentcloud.rag.ai.retrieval.RetrievalQuery;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;

import java.text.Normalizer;
import java.util.List;

@Service
@ConditionalOnProperty(prefix = "rag.retrieval", name = "enabled", havingValue = "true")
public class RagQueryService {

    private static final int MAX_TOP_K = 50;

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
        int topK = normalizeTopK(request == null ? null : request.topK());

        // Derive ACL exclusively from the server-side security context; the client
        // request carries no ACL fields at all.
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        String userId = null;
        List<String> roles = List.of();
        String department = null;
        if (authentication != null && authentication.isAuthenticated() && !"anonymousUser".equals(authentication.getPrincipal())) {
            userId = authentication.getName();
            roles = authentication.getAuthorities().stream()
                    .map(authority -> SecurityRoleUtils.normalizeRoleCode(authority.getAuthority()))
                    .filter(role -> !role.isBlank())
                    .toList();
            department = resolveDepartment(roles);
        }

        RetrievalQuery query = new RetrievalQuery(
                normalizedQuery,
                aclFilterService.context(userId, roles, department),
                topK
        );
        return hybridRetriever.retrieve(query);
    }

    private static int normalizeTopK(Integer requestedTopK) {
        if (requestedTopK == null) {
            return 10;
        }
        return Math.max(1, Math.min(requestedTopK, MAX_TOP_K));
    }

    private static String resolveDepartment(List<String> roles) {
        for (String role : roles) {
            if ("SUPER_ADMIN".equals(role) || "ADMIN".equals(role)) {
                return "ALL";
            } else if ("TRAFFIC_POLICE".equals(role) || "FINANCE".equals(role) || "APPEAL_REVIEWER".equals(role)) {
                return "DEPARTMENT";
            }
        }
        return null;
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