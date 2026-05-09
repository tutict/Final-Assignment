package com.tutict.finalassignmentbackend.offense.governance;

import java.time.LocalDateTime;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;

public record OffenseGovernanceDecision(
        OffenseGovernanceDecisionType type,
        SemanticEventType semanticEventType,
        EnforcementMode enforcementMode,
        Source source,
        Long offenseId,
        LocalDateTime updatedAt,
        List<String> fields,
        Map<String, Object> attributes
) {
    public OffenseGovernanceDecision {
        type = Objects.requireNonNull(type, "type must not be null");
        semanticEventType = semanticEventType == null ? SemanticEventType.UNKNOWN : semanticEventType;
        enforcementMode = Objects.requireNonNull(enforcementMode, "enforcementMode must not be null");
        source = Objects.requireNonNull(source, "source must not be null");
        fields = fields == null ? List.of() : List.copyOf(fields);
        attributes = freeze(attributes);
    }

    public OffenseGovernanceDecision withAttribute(String key, Object value) {
        if (key == null || key.isBlank()) {
            return this;
        }
        LinkedHashMap<String, Object> copy = new LinkedHashMap<>(attributes);
        copy.put(key, value);
        return new OffenseGovernanceDecision(
                type,
                semanticEventType,
                enforcementMode,
                source,
                offenseId,
                updatedAt,
                fields,
                copy
        );
    }

    public boolean isShadowOnly() {
        return enforcementMode == EnforcementMode.SHADOW;
    }

    public boolean isEnforced() {
        return enforcementMode == EnforcementMode.ENFORCED;
    }

    public boolean isCompatibilityFallback() {
        return enforcementMode == EnforcementMode.COMPATIBILITY_FALLBACK
                || type == OffenseGovernanceDecisionType.LEGACY_COMPATIBILITY_MODE;
    }

    private static Map<String, Object> freeze(Map<String, Object> attributes) {
        if (attributes == null || attributes.isEmpty()) {
            return Map.of();
        }
        return Collections.unmodifiableMap(new LinkedHashMap<>(attributes));
    }

    public enum EnforcementMode {
        SHADOW,
        ENFORCED,
        COMPATIBILITY_FALLBACK
    }

    public enum Source {
        CONTROLLER,
        KAFKA,
        WORKFLOW,
        QUERY_REPAIR
    }
}
