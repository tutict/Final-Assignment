package com.tutict.finalassignmentbackend.offense.governance;

import java.time.LocalDateTime;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

public final class OffenseGovernanceLogFactory {

    private OffenseGovernanceLogFactory() {
    }

    public static OffenseGovernanceDecision staleKafkaRejected(Long offenseId,
                                                              LocalDateTime currentUpdatedAt,
                                                              LocalDateTime incomingUpdatedAt) {
        return new OffenseGovernanceDecision(
                OffenseGovernanceDecisionType.STALE_REJECTED,
                SemanticEventType.FULL_UPDATE,
                OffenseGovernanceDecision.EnforcementMode.ENFORCED,
                OffenseGovernanceDecision.Source.KAFKA,
                offenseId,
                incomingUpdatedAt,
                List.of(),
                attributes(
                        "currentUpdatedAt", currentUpdatedAt,
                        "incomingUpdatedAt", incomingUpdatedAt
                )
        );
    }

    public static OffenseGovernanceDecision shadowStale(OffenseGovernanceDecision.Source source,
                                                        Long offenseId,
                                                        LocalDateTime currentUpdatedAt,
                                                        LocalDateTime incomingUpdatedAt) {
        return new OffenseGovernanceDecision(
                OffenseGovernanceDecisionType.SHADOW_STALE,
                SemanticEventType.FULL_UPDATE,
                OffenseGovernanceDecision.EnforcementMode.SHADOW,
                source,
                offenseId,
                incomingUpdatedAt,
                List.of(),
                attributes(
                        "currentUpdatedAt", currentUpdatedAt,
                        "incomingUpdatedAt", incomingUpdatedAt
                )
        );
    }

    public static OffenseGovernanceDecision workflowStaleRejected(Long offenseId,
                                                                  String currentStatus,
                                                                  String incomingStatus,
                                                                  LocalDateTime currentProcessTime,
                                                                  LocalDateTime incomingProcessTime) {
        return new OffenseGovernanceDecision(
                OffenseGovernanceDecisionType.STALE_REJECTED,
                SemanticEventType.WORKFLOW,
                OffenseGovernanceDecision.EnforcementMode.ENFORCED,
                OffenseGovernanceDecision.Source.WORKFLOW,
                offenseId,
                null,
                List.of("processStatus", "processTime"),
                attributes(
                        "currentProcessStatus", currentStatus,
                        "incomingProcessStatus", incomingStatus,
                        "currentProcessTime", currentProcessTime,
                        "incomingProcessTime", incomingProcessTime
                )
        );
    }

    public static OffenseGovernanceDecision noOpSuppressed(OffenseGovernanceDecision.Source source,
                                                           Long offenseId,
                                                           String reason) {
        return new OffenseGovernanceDecision(
                OffenseGovernanceDecisionType.NO_OP_SUPPRESSED,
                SemanticEventType.NO_OP,
                OffenseGovernanceDecision.EnforcementMode.ENFORCED,
                source,
                offenseId,
                null,
                List.of(),
                attributes("reason", reason)
        );
    }

    public static OffenseGovernanceDecision nullFieldPreserved(OffenseGovernanceDecision.Source source,
                                                               Long offenseId,
                                                               FullUpdateCompatibilityMode mode,
                                                               LocalDateTime updatedAt,
                                                               List<String> fields) {
        return mergeDecision(
                OffenseGovernanceDecisionType.NULL_FIELD_PRESERVED,
                source,
                offenseId,
                mode,
                updatedAt,
                fields
        );
    }

    public static OffenseGovernanceDecision immutableFieldPreserved(OffenseGovernanceDecision.Source source,
                                                                    Long offenseId,
                                                                    FullUpdateCompatibilityMode mode,
                                                                    LocalDateTime updatedAt,
                                                                    List<String> fields) {
        return mergeDecision(
                OffenseGovernanceDecisionType.IMMUTABLE_FIELD_PRESERVED,
                source,
                offenseId,
                mode,
                updatedAt,
                fields
        );
    }

    public static OffenseGovernanceDecision workflowFieldSuppressed(OffenseGovernanceDecision.Source source,
                                                                    Long offenseId,
                                                                    FullUpdateCompatibilityMode mode,
                                                                    LocalDateTime updatedAt,
                                                                    List<String> fields) {
        return mergeDecision(
                OffenseGovernanceDecisionType.WORKFLOW_FIELD_SUPPRESSED,
                source,
                offenseId,
                mode,
                updatedAt,
                fields
        );
    }

    public static OffenseGovernanceDecision legacyCompatibilityMode(Long offenseId,
                                                                    FullUpdateCompatibilityMode mode,
                                                                    LocalDateTime updatedAt,
                                                                    List<String> fields) {
        return legacyCompatibilityMode(OffenseGovernanceDecision.Source.CONTROLLER, offenseId, mode, updatedAt, fields);
    }

    public static OffenseGovernanceDecision legacyCompatibilityMode(OffenseGovernanceDecision.Source source,
                                                                    Long offenseId,
                                                                    FullUpdateCompatibilityMode mode,
                                                                    LocalDateTime updatedAt,
                                                                    List<String> fields) {
        return new OffenseGovernanceDecision(
                OffenseGovernanceDecisionType.LEGACY_COMPATIBILITY_MODE,
                SemanticEventType.FULL_UPDATE,
                OffenseGovernanceDecision.EnforcementMode.COMPATIBILITY_FALLBACK,
                source,
                offenseId,
                updatedAt,
                fields,
                attributes("compatibilityMode", mode)
        );
    }

    public static OffenseGovernanceDecision readRepairTriggered(Long offenseId, int recordCount) {
        return new OffenseGovernanceDecision(
                OffenseGovernanceDecisionType.READ_REPAIR_TRIGGERED,
                SemanticEventType.SYSTEM,
                OffenseGovernanceDecision.EnforcementMode.ENFORCED,
                OffenseGovernanceDecision.Source.QUERY_REPAIR,
                offenseId,
                null,
                List.of(),
                attributes("recordCount", recordCount)
        );
    }

    public static String format(OffenseGovernanceDecision decision) {
        StringBuilder payload = new StringBuilder();
        append(payload, "governance", decision.type());
        append(payload, "semantic", decision.semanticEventType());
        append(payload, "enforcement", decision.enforcementMode());
        append(payload, "source", decision.source());
        if (decision.offenseId() != null) {
            append(payload, "offenseId", decision.offenseId());
        }
        if (decision.updatedAt() != null) {
            append(payload, "updatedAt", decision.updatedAt());
        }
        if (!decision.fields().isEmpty()) {
            append(payload, "fields", decision.fields());
        }
        decision.attributes().forEach((key, value) -> append(payload, key, value));
        return payload.toString();
    }

    private static OffenseGovernanceDecision mergeDecision(OffenseGovernanceDecisionType type,
                                                           OffenseGovernanceDecision.Source source,
                                                           Long offenseId,
                                                           FullUpdateCompatibilityMode mode,
                                                           LocalDateTime updatedAt,
                                                           List<String> fields) {
        return new OffenseGovernanceDecision(
                type,
                SemanticEventType.FULL_UPDATE,
                enforcementMode(mode),
                source,
                offenseId,
                updatedAt,
                fields,
                attributes("compatibilityMode", mode)
        );
    }

    private static OffenseGovernanceDecision.EnforcementMode enforcementMode(FullUpdateCompatibilityMode mode) {
        if (mode != null && mode.enforceGuardedMerge()) {
            return OffenseGovernanceDecision.EnforcementMode.ENFORCED;
        }
        return OffenseGovernanceDecision.EnforcementMode.COMPATIBILITY_FALLBACK;
    }

    private static Map<String, Object> attributes(Object... keyValues) {
        LinkedHashMap<String, Object> result = new LinkedHashMap<>();
        for (int i = 0; i + 1 < keyValues.length; i += 2) {
            Object key = keyValues[i];
            if (key != null) {
                result.put(String.valueOf(key), keyValues[i + 1]);
            }
        }
        return result;
    }

    private static void append(StringBuilder payload, String key, Object value) {
        if (payload.length() > 0) {
            payload.append(' ');
        }
        payload.append(key).append('=').append(value(value));
    }

    private static String value(Object value) {
        if (value == null) {
            return "null";
        }
        if (value instanceof Iterable<?> iterable) {
            return "[" + stream(iterable).collect(Collectors.joining(",")) + "]";
        }
        return String.valueOf(value).replaceAll("\\s+", "_");
    }

    private static java.util.stream.Stream<String> stream(Iterable<?> iterable) {
        java.util.stream.Stream.Builder<String> builder = java.util.stream.Stream.builder();
        iterable.forEach(value -> builder.add(value(value)));
        return builder.build();
    }
}
