package com.tutict.finalassignmentbackend.appeal.application;

import com.tutict.finalassignmentbackend.entity.appeal.AppealRecord;

import java.util.Objects;

/**
 * Explicit protocol outcome for an authenticated appeal creation attempt.
 */
public record AppealCreationResult(Status status, AppealRecord appeal) {

    public enum Status {
        CREATED,
        DUPLICATE,
        COLLISION
    }

    public AppealCreationResult {
        Objects.requireNonNull(status, "Appeal creation status cannot be null");
        if (status == Status.CREATED) {
            Objects.requireNonNull(appeal, "Created appeal cannot be null");
        } else if (appeal != null) {
            throw new IllegalArgumentException("Duplicate and collision outcomes cannot carry an appeal");
        }
    }

    public static AppealCreationResult created(AppealRecord appeal) {
        return new AppealCreationResult(Status.CREATED, appeal);
    }

    public static AppealCreationResult duplicate() {
        return new AppealCreationResult(Status.DUPLICATE, null);
    }

    public static AppealCreationResult collision() {
        return new AppealCreationResult(Status.COLLISION, null);
    }
}
