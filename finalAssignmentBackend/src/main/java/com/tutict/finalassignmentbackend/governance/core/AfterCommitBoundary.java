package com.tutict.finalassignmentbackend.governance.core;

@FunctionalInterface
public interface AfterCommitBoundary {

    void afterCommit(Runnable sideEffect);

    static AfterCommitBoundary immediate() {
        return Runnable::run;
    }
}
