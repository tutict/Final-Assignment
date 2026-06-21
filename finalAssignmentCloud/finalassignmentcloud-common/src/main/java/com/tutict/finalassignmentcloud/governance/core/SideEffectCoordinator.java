package com.tutict.finalassignmentcloud.governance.core;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.List;
import java.util.Objects;

/**
 * Side Effect Coordinator
 * Coordinates side effects after transaction commit
 */
public final class SideEffectCoordinator {

    private static final Logger log = LoggerFactory.getLogger(SideEffectCoordinator.class);

    private final AfterCommitBoundary afterCommitBoundary;

    public SideEffectCoordinator(AfterCommitBoundary afterCommitBoundary) {
        this.afterCommitBoundary = Objects.requireNonNull(afterCommitBoundary, "AfterCommitBoundary cannot be null");
        log.debug("SideEffectCoordinator initialized with boundary: {}", afterCommitBoundary.getClass().getSimpleName());
    }

    public void afterCommit(MutationSideEffectPolicy policy, List<Runnable> sideEffects) {
        if (policy == null || !policy.requiresAfterCommit() || sideEffects == null || sideEffects.isEmpty()) {
            log.trace("Skipping side effects: policy={}, requiresAfterCommit=, sideEffects={}",
                     policy != null ? policy.getClass().getSimpleName() : "null",
                     policy != null && policy.requiresAfterCommit(),
                     sideEffects != null ? sideEffects.size() : 0);
            return;
        }

        log.info("Coordinating {} side effects after commit with policy: {}",
                sideEffects.size(), policy.getClass().getSimpleName());

        int executedCount = 0;
        for (Runnable sideEffect : sideEffects) {
            if (sideEffect != null) {
                log.debug("Scheduling side effect #{}: {}", executedCount + 1, sideEffect.getClass().getSimpleName());
                afterCommitBoundary.afterCommit(sideEffect);
                executedCount++;
            }
        }

        log.info("Successfully scheduled {} side effects for after-commit execution", executedCount);
    }
}
