package com.tutict.finalassignmentbackend.ai.rag.retrieval;

import com.tutict.finalassignmentbackend.ai.rag.dto.RetrievalResult;
import org.springframework.stereotype.Service;

import java.util.Collection;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Objects;
import java.util.Set;
import java.util.stream.Collectors;

@Service
public class AclFilterService {

    public AccessContext context(String userId, List<String> roles, String department) {
        return new AccessContext(
                blankToNull(userId),
                normalizeSet(roles),
                blankToNull(department)
        );
    }

    public AclFilter buildFilter(AccessContext context) {
        AccessContext effective = context == null ? new AccessContext(null, Set.of(), null) : context;
        return new AclFilter(effective.userId(), effective.roles(), effective.department());
    }

    public boolean allows(RetrievalResult result, AccessContext context) {
        String scope = metadataString(result.metadata(), "aclScope", "acl_scope")
                .toUpperCase(Locale.ROOT);
        if (scope.isBlank() || "PUBLIC".equals(scope)) {
            return true;
        }
        AccessContext effective = context == null ? new AccessContext(null, Set.of(), null) : context;
        return switch (scope) {
            case "ROLE" -> intersects(effective.roles(), metadataValues(result.metadata(), "roles", "aclRoles", "acl_roles"));
            case "USER" -> effective.userId() != null
                    && metadataValues(result.metadata(), "userIds", "userId", "aclUserIds", "acl_user_ids")
                    .contains(effective.userId());
            case "DEPARTMENT" -> effective.department() != null
                    && metadataValues(result.metadata(), "departments", "department", "aclDepartments", "acl_departments")
                    .contains(effective.department());
            default -> false;
        };
    }

    private static boolean intersects(Set<String> left, Set<String> right) {
        return left.stream().anyMatch(right::contains);
    }

    private static Set<String> normalizeSet(Collection<String> values) {
        if (values == null) {
            return Set.of();
        }
        return values.stream()
                .filter(Objects::nonNull)
                .map(String::trim)
                .filter(value -> !value.isBlank())
                .collect(Collectors.toUnmodifiableSet());
    }

    private static Set<String> metadataValues(Map<String, Object> metadata, String... keys) {
        for (String key : keys) {
            Object value = metadata.get(key);
            if (value instanceof Collection<?> collection) {
                return collection.stream()
                        .filter(Objects::nonNull)
                        .map(Object::toString)
                        .collect(Collectors.toUnmodifiableSet());
            }
            if (value != null && !value.toString().isBlank()) {
                return Set.of(value.toString());
            }
        }
        return Set.of();
    }

    private static String metadataString(Map<String, Object> metadata, String... keys) {
        for (String key : keys) {
            Object value = metadata.get(key);
            if (value != null && !value.toString().isBlank()) {
                return value.toString();
            }
        }
        return "PUBLIC";
    }

    private static String blankToNull(String value) {
        return value == null || value.isBlank() ? null : value.trim();
    }

    public record AccessContext(
            String userId,
            Set<String> roles,
            String department
    ) {
        public AccessContext {
            roles = roles == null ? Set.of() : Set.copyOf(roles);
        }
    }

    public record AclFilter(
            String userId,
            Set<String> roles,
            String department
    ) {
        public AclFilter {
            roles = roles == null ? Set.of() : Set.copyOf(roles);
        }
    }
}
