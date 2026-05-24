package com.tutict.finalassignmentbackend.payment.governance;

import com.tutict.finalassignmentbackend.entity.payment.PaymentRecord;

import java.util.LinkedHashMap;
import java.util.Map;
import java.util.stream.Collectors;

public final class PaymentGovernanceLogFactory {

    private static final String ROLLOUT_MODE = "SHADOW";

    private PaymentGovernanceLogFactory() {
    }

    public static String shadowClassification(PaymentGovernanceSource source,
                                              PaymentGovernanceClassifier.Classification classification,
                                              PaymentRecord record,
                                              String action) {
        return format(PaymentGovernanceDecisionType.SHADOW_CLASSIFIED, source, classification, record,
                attributes("action", action));
    }

    public static String preMutationKafka(PaymentGovernanceSource source,
                                          PaymentGovernanceClassifier.Classification classification,
                                          PaymentRecord record,
                                          String action,
                                          String idempotencyKey) {
        return format(PaymentGovernanceDecisionType.PRE_MUTATION_KAFKA_SHADOW, source, classification, record,
                attributes("action", action, "idempotencyKey", idempotencyKey));
    }

    public static String noOpSuppressed(PaymentGovernanceSource source,
                                        PaymentGovernanceClassifier.Classification classification,
                                        PaymentRecord record,
                                        String action,
                                        String idempotencyKey) {
        return format(PaymentGovernanceDecisionType.NO_OP_SUPPRESSED, source, classification, record,
                attributes("action", action, "idempotencyKey", idempotencyKey));
    }

    public static String workflowStatus(PaymentGovernanceClassifier.Classification classification,
                                        PaymentRecord record,
                                        String requestedState) {
        return format(PaymentGovernanceDecisionType.WORKFLOW_STATUS_SHADOW, PaymentGovernanceSource.WORKFLOW,
                classification, record, attributes("requestedState", requestedState));
    }

    public static String readRepair(PaymentGovernanceClassifier.Classification classification,
                                    Long paymentId,
                                    int recordCount) {
        return format(PaymentGovernanceDecisionType.READ_REPAIR_SHADOW, PaymentGovernanceSource.QUERY_REPAIR,
                classification, null, attributes("paymentId", paymentId, "recordCount", recordCount));
    }

    private static String format(PaymentGovernanceDecisionType decisionType,
                                 PaymentGovernanceSource source,
                                 PaymentGovernanceClassifier.Classification classification,
                                 PaymentRecord record,
                                 Map<String, Object> attributes) {
        StringBuilder payload = new StringBuilder();
        append(payload, "paymentGovernance", decisionType);
        append(payload, "rolloutMode", ROLLOUT_MODE);
        append(payload, "source", source);
        append(payload, "semantic", classification.semanticEventType());
        append(payload, "sideEffects", classification.sideEffects());
        if (record != null) {
            append(payload, "paymentId", record.getPaymentId());
            append(payload, "fineId", record.getFineId());
            append(payload, "paymentStatus", record.getPaymentStatus());
        }
        attributes.forEach((key, value) -> append(payload, key, value));
        return payload.toString();
    }

    private static Map<String, Object> attributes(Object... keyValues) {
        LinkedHashMap<String, Object> result = new LinkedHashMap<>();
        for (int i = 0; i + 1 < keyValues.length; i += 2) {
            if (keyValues[i] != null) {
                result.put(String.valueOf(keyValues[i]), keyValues[i + 1]);
            }
        }
        return result;
    }

    private static void append(StringBuilder payload, String key, Object value) {
        if (value == null) {
            return;
        }
        if (payload.length() > 0) {
            payload.append(' ');
        }
        payload.append(key).append('=').append(value(value));
    }

    private static String value(Object value) {
        if (value instanceof Iterable<?> iterable) {
            return "[" + stream(iterable).sorted().collect(Collectors.joining(",")) + "]";
        }
        return String.valueOf(value).replaceAll("\\s+", "_");
    }

    private static java.util.stream.Stream<String> stream(Iterable<?> iterable) {
        java.util.stream.Stream.Builder<String> builder = java.util.stream.Stream.builder();
        iterable.forEach(value -> builder.add(value(value)));
        return builder.build();
    }
}
