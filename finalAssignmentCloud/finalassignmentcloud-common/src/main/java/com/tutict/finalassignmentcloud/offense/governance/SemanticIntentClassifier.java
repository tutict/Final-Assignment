package com.tutict.finalassignmentcloud.offense.governance;

public final class SemanticIntentClassifier {

    public MutationSideEffectPolicy classifyCreate() {
        return MutationSideEffectPolicy.of(
                SemanticEventType.FULL_UPDATE,
                MutationSideEffect.DB_MUTATION,
                MutationSideEffect.ES_INDEX,
                MutationSideEffect.CACHE_EVICT
        );
    }

    public MutationSideEffectPolicy classifyUpdate() {
        return MutationSideEffectPolicy.of(
                SemanticEventType.FULL_UPDATE,
                MutationSideEffect.DB_MUTATION,
                MutationSideEffect.ES_INDEX,
                MutationSideEffect.CACHE_EVICT
        );
    }

    public MutationSideEffectPolicy classifyDelete() {
        return MutationSideEffectPolicy.of(
                SemanticEventType.SYSTEM,
                MutationSideEffect.DB_MUTATION,
                MutationSideEffect.ES_INDEX,
                MutationSideEffect.CACHE_EVICT
        );
    }

    public MutationSideEffectPolicy classifyWorkflow() {
        return MutationSideEffectPolicy.of(
                SemanticEventType.WORKFLOW,
                MutationSideEffect.DB_MUTATION,
                MutationSideEffect.ES_INDEX
        );
    }

    public MutationSideEffectPolicy classifyReadRepair() {
        return MutationSideEffectPolicy.of(
                SemanticEventType.SYSTEM,
                MutationSideEffect.READ_REPAIR,
                MutationSideEffect.ES_INDEX
        );
    }

    public MutationSideEffectPolicy classifyDuplicate() {
        return MutationSideEffectPolicy.of(SemanticEventType.NO_OP, MutationSideEffect.NONE);
    }

    public MutationSideEffectPolicy classifyIdempotencyPublish(String action) {
        return MutationSideEffectPolicy.of(classifyAction(action), MutationSideEffect.KAFKA_PUBLISH, MutationSideEffect.CACHE_EVICT);
    }

    public MutationSideEffectPolicy classifyKafkaAction(String action, boolean duplicate) {
        if (duplicate) {
            return classifyDuplicate();
        }
        SemanticEventType type = classifyAction(action);
        if (type == SemanticEventType.UNKNOWN) {
            return MutationSideEffectPolicy.of(type, MutationSideEffect.NONE);
        }
        return MutationSideEffectPolicy.of(
                type,
                MutationSideEffect.DB_MUTATION,
                MutationSideEffect.ES_INDEX,
                MutationSideEffect.CACHE_EVICT
        );
    }

    private SemanticEventType classifyAction(String action) {
        if ("create".equalsIgnoreCase(action) || "update".equalsIgnoreCase(action)) {
            return SemanticEventType.FULL_UPDATE;
        }
        return SemanticEventType.UNKNOWN;
    }
}
