package com.tutict.finalassignmentcloud.governance.core;

import java.util.List;
import java.util.Objects;

public final class SideEffectCoordinator {

    private final AfterCommitBoundary afterCommitBoundary;

    public SideEffectCoordinator(AfterCommitBoundary afterCommitBoundary) {
        this.afterCommitBoundary = Objects.requireNonNull(afterCommitBoundary, "AfterCommitBoundary cannot be null");
    }

    public void afterCommit(MutationSideEffectPolicy policy, List<Runnable> sideEffects) {
        if (policy == null || !policy.requiresAfterCommit() || sideEffects == null || sideEffects.isEmpty()) {
            return;
        }
        for (Runnable sideEffect : sideEffects) {
            if (sideEffect != null) {
                afterCommitBoundary.afterCommit(sideEffect);
            }
        }
    }
}
