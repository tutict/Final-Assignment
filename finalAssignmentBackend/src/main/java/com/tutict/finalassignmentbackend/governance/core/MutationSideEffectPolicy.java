package com.tutict.finalassignmentbackend.governance.core;

public record MutationSideEffectPolicy(
        SemanticMutationType mutationType,
        boolean duplicate,
        boolean mutatesState,
        boolean publishesMessage,
        boolean reindexesSearch,
        boolean evictsCache,
        boolean notifiesRealtime,
        boolean indexesRetrieval,
        boolean requiresAfterCommit
) {
    public static MutationSideEffectPolicy mutating(
            SemanticMutationType mutationType,
            boolean publishesMessage,
            boolean reindexesSearch,
            boolean evictsCache,
            boolean notifiesRealtime,
            boolean indexesRetrieval
    ) {
        if (mutationType == null || mutationType == SemanticMutationType.NO_OP) {
            throw new IllegalArgumentException("Mutating policy requires a concrete mutation type");
        }
        return new MutationSideEffectPolicy(
                mutationType,
                false,
                true,
                publishesMessage,
                reindexesSearch,
                evictsCache,
                notifiesRealtime,
                indexesRetrieval,
                hasSideEffect(publishesMessage, reindexesSearch, evictsCache, notifiesRealtime, indexesRetrieval)
        );
    }

    public static MutationSideEffectPolicy noOp(boolean duplicate) {
        return new MutationSideEffectPolicy(
                SemanticMutationType.NO_OP,
                duplicate,
                false,
                false,
                false,
                false,
                false,
                false,
                false
        );
    }

    public boolean hasSideEffects() {
        return publishesMessage || reindexesSearch || evictsCache || notifiesRealtime || indexesRetrieval;
    }

    private static boolean hasSideEffect(boolean... flags) {
        for (boolean flag : flags) {
            if (flag) {
                return true;
            }
        }
        return false;
    }
}
