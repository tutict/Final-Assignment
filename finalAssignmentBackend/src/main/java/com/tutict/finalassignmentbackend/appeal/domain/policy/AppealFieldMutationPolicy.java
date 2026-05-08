package com.tutict.finalassignmentbackend.appeal.domain.policy;

import com.tutict.finalassignmentbackend.entity.AppealRecord;

import java.util.Objects;
import java.util.Set;

public class AppealFieldMutationPolicy {

    private static final Set<String> IMMUTABLE_FIELDS = Set.of(
            "appealId",
            "offenseId",
            "appealNumber",
            "appealTime"
    );

    private static final Set<String> MUTABLE_FIELDS = Set.of(
            "appellantName",
            "appellantIdCard",
            "appellantContact",
            "appellantEmail",
            "appellantAddress",
            "appealType",
            "appealReason",
            "evidenceDescription",
            "evidenceUrls",
            "remarks"
    );

    private static final Set<String> SYSTEM_MANAGED_FIELDS = Set.of(
            "acceptanceStatus",
            "acceptanceTime",
            "acceptanceHandler",
            "rejectionReason",
            "processStatus",
            "processTime",
            "processResult",
            "processHandler",
            "createdAt",
            "updatedAt",
            "createdBy",
            "updatedBy",
            "deletedAt"
    );

    private static final Set<String> TERMINAL_PROTECTED_FIELDS = Set.of(
            "appellantName",
            "appellantIdCard",
            "appellantContact",
            "appellantEmail",
            "appellantAddress",
            "appealType",
            "appealReason",
            "evidenceDescription",
            "evidenceUrls"
    );

    private final AppealTransitionPolicy transitionPolicy = new AppealTransitionPolicy();

    public Set<String> immutableFields() {
        return Set.copyOf(IMMUTABLE_FIELDS);
    }

    public Set<String> mutableFields() {
        return Set.copyOf(MUTABLE_FIELDS);
    }

    public Set<String> systemManagedFields() {
        return Set.copyOf(SYSTEM_MANAGED_FIELDS);
    }

    public Set<String> terminalProtectedFields() {
        return Set.copyOf(TERMINAL_PROTECTED_FIELDS);
    }

    public boolean isTerminalState(AppealRecord existing) {
        return existing != null && transitionPolicy.isTerminal(existing.getProcessStatus());
    }

    public <T> T mergeMutableField(String fieldName, T existingValue, T incomingValue, boolean terminalState) {
        if (incomingValue == null) {
            return existingValue;
        }
        if (terminalState
                && TERMINAL_PROTECTED_FIELDS.contains(fieldName)
                && !Objects.equals(existingValue, incomingValue)) {
            throw new IllegalStateException("Cannot update terminal appeal field: " + fieldName);
        }
        return incomingValue;
    }

    public <T> T preserveExisting(T existingValue) {
        return existingValue;
    }
}
