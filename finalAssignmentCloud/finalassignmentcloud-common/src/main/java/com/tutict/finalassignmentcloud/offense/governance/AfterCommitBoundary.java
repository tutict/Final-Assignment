package com.tutict.finalassignmentcloud.offense.governance;

import org.springframework.transaction.support.TransactionSynchronization;
import org.springframework.transaction.support.TransactionSynchronizationManager;

public final class AfterCommitBoundary {

    public void afterCommit(Runnable sideEffect) {
        if (!TransactionSynchronizationManager.isSynchronizationActive()) {
            sideEffect.run();
            return;
        }
        TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
            @Override
            public void afterCommit() {
                sideEffect.run();
            }
        });
    }
}
