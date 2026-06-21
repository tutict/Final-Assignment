package com.tutict.finalassignmentcloud.payment.governance;

import com.tutict.finalassignmentcloud.entity.payment.PaymentState;

import java.util.Arrays;
import java.util.EnumSet;
import java.util.Set;

public final class PaymentGovernanceClassifier {

    public Classification classifyControllerMutation(String action, boolean duplicate) {
        if (duplicate) {
            return Classification.of(PaymentSemanticEventType.NO_OP, PaymentSideEffect.NONE);
        }
        PaymentSemanticEventType semantic = classifyAction(action);
        return Classification.of(semantic, PaymentSideEffect.DB_MUTATION, PaymentSideEffect.ES_INDEX, PaymentSideEffect.CACHE_EVICT);
    }

    public Classification classifyPreMutationKafka(String action) {
        return Classification.of(classifyAction(action), PaymentSideEffect.KAFKA_PUBLISH);
    }

    public Classification classifyKafkaMutation(String action, boolean duplicate) {
        if (duplicate) {
            return Classification.of(PaymentSemanticEventType.NO_OP, PaymentSideEffect.NONE);
        }
        PaymentSemanticEventType semantic = classifyAction(action);
        if (semantic == PaymentSemanticEventType.UNKNOWN) {
            return Classification.of(semantic, PaymentSideEffect.NONE);
        }
        return Classification.of(semantic, PaymentSideEffect.DB_MUTATION, PaymentSideEffect.ES_INDEX, PaymentSideEffect.CACHE_EVICT);
    }

    public Classification classifyServiceMutation(String action) {
        PaymentSemanticEventType semantic = classifyAction(action);
        if (semantic == PaymentSemanticEventType.UNKNOWN) {
            return Classification.of(semantic, PaymentSideEffect.NONE);
        }
        return Classification.of(semantic, PaymentSideEffect.DB_MUTATION, PaymentSideEffect.ES_INDEX, PaymentSideEffect.CACHE_EVICT);
    }

    public Classification classifyWorkflowStatus(PaymentState state) {
        if (state == PaymentState.PAID) {
            return Classification.of(
                    PaymentSemanticEventType.WORKFLOW,
                    PaymentSideEffect.DB_MUTATION,
                    PaymentSideEffect.ES_INDEX,
                    PaymentSideEffect.WORKFLOW_TRANSITION,
                    PaymentSideEffect.PAYMENT_COMPLETION
            );
        }
        return Classification.of(
                PaymentSemanticEventType.WORKFLOW,
                PaymentSideEffect.DB_MUTATION,
                PaymentSideEffect.ES_INDEX,
                PaymentSideEffect.WORKFLOW_TRANSITION
        );
    }

    public Classification classifyDelete() {
        return Classification.of(PaymentSemanticEventType.SYSTEM, PaymentSideEffect.DB_MUTATION, PaymentSideEffect.ES_INDEX, PaymentSideEffect.CACHE_EVICT);
    }

    public Classification classifyReadRepair() {
        return Classification.of(PaymentSemanticEventType.READ_REPAIR, PaymentSideEffect.READ_REPAIR, PaymentSideEffect.ES_INDEX);
    }

    private PaymentSemanticEventType classifyAction(String action) {
        if ("create".equalsIgnoreCase(action) || "update".equalsIgnoreCase(action)) {
            return PaymentSemanticEventType.FULL_UPDATE;
        }
        return PaymentSemanticEventType.UNKNOWN;
    }

    public record Classification(
            PaymentSemanticEventType semanticEventType,
            Set<PaymentSideEffect> sideEffects
    ) {
        public static Classification of(PaymentSemanticEventType semanticEventType, PaymentSideEffect... sideEffects) {
            return new Classification(
                    semanticEventType == null ? PaymentSemanticEventType.UNKNOWN : semanticEventType,
                    normalize(sideEffects)
            );
        }

        public boolean has(PaymentSideEffect sideEffect) {
            return sideEffects.contains(sideEffect);
        }

        private static Set<PaymentSideEffect> normalize(PaymentSideEffect[] sideEffects) {
            if (sideEffects == null || sideEffects.length == 0) {
                return Set.of(PaymentSideEffect.NONE);
            }
            EnumSet<PaymentSideEffect> normalized = EnumSet.noneOf(PaymentSideEffect.class);
            Arrays.stream(sideEffects)
                    .filter(effect -> effect != null)
                    .forEach(normalized::add);
            if (normalized.isEmpty()) {
                normalized.add(PaymentSideEffect.NONE);
            }
            if (normalized.size() > 1) {
                normalized.remove(PaymentSideEffect.NONE);
            }
            return Set.copyOf(normalized);
        }
    }
}
