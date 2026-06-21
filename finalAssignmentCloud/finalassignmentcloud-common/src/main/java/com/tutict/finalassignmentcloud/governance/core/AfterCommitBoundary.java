package com.tutict.finalassignmentcloud.governance.core;

@FunctionalInterface
public interface AfterCommitBoundary {

    void afterCommit(Runnable sideEffect);

    static AfterCommitBoundary immediate() {
        return Runnable::run;
    }
}
