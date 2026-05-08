package com.tutict.finalassignmentbackend.offense.governance;

import java.util.Objects;

public final class OffenseSideEffectCoordinator {

    private final AfterCommitBoundary afterCommitBoundary;

    public OffenseSideEffectCoordinator(AfterCommitBoundary afterCommitBoundary) {
        this.afterCommitBoundary = Objects.requireNonNull(afterCommitBoundary, "afterCommitBoundary must not be null");
    }

    public void publishKafkaNow(MutationSideEffectPolicy policy, Runnable publisher) {
        runIf(policy, MutationSideEffect.KAFKA_PUBLISH, publisher);
    }

    public void indexAfterCommit(MutationSideEffectPolicy policy, Runnable indexer) {
        if (has(policy, MutationSideEffect.ES_INDEX)) {
            afterCommitBoundary.afterCommit(indexer);
        }
    }

    public void readRepairNow(MutationSideEffectPolicy policy, Runnable readRepair) {
        runIf(policy, MutationSideEffect.READ_REPAIR, readRepair);
    }

    private void runIf(MutationSideEffectPolicy policy, MutationSideEffect sideEffect, Runnable action) {
        if (has(policy, sideEffect)) {
            action.run();
        }
    }

    private boolean has(MutationSideEffectPolicy policy, MutationSideEffect sideEffect) {
        return policy != null && policy.has(sideEffect);
    }
}
