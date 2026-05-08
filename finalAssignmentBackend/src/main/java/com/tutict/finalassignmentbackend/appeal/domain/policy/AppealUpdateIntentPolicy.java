package com.tutict.finalassignmentbackend.appeal.domain.policy;

import com.tutict.finalassignmentbackend.entity.AppealRecord;

import java.util.Objects;
import java.util.Set;
import java.util.function.Function;

public class AppealUpdateIntentPolicy {

    public enum UpdateIntent {
        FULL_UPDATE,
        PARTIAL_UPDATE,
        WORKFLOW_UPDATE,
        SYSTEM_UPDATE
    }

    private static final Set<String> WORKFLOW_FIELDS = Set.of(
            "processStatus",
            "processTime",
            "processResult",
            "processHandler"
    );

    private final AppealFieldMutationPolicy fieldMutationPolicy = new AppealFieldMutationPolicy();

    public Set<String> allowedFields(UpdateIntent intent) {
        return switch (intent) {
            case FULL_UPDATE, PARTIAL_UPDATE -> fieldMutationPolicy.mutableFields();
            case WORKFLOW_UPDATE -> Set.copyOf(WORKFLOW_FIELDS);
            case SYSTEM_UPDATE -> fieldMutationPolicy.systemManagedFields();
        };
    }

    public void validateIntent(AppealRecord existing, AppealRecord incoming, UpdateIntent intent) {
        if (intent == null) {
            throw new IllegalArgumentException("Appeal update intent cannot be null");
        }
        if (isStaleUpdate(existing, incoming)) {
            throw new IllegalStateException("Stale appeal update rejected");
        }
        if (intent == UpdateIntent.WORKFLOW_UPDATE && hasBusinessFieldMutation(existing, incoming)) {
            throw new IllegalStateException("Illegal appeal update intent mutation: WORKFLOW_UPDATE cannot change business fields");
        }
        if (intent == UpdateIntent.SYSTEM_UPDATE && hasBusinessFieldMutation(existing, incoming)) {
            throw new IllegalStateException("Illegal appeal update intent mutation: SYSTEM_UPDATE cannot change business fields");
        }
    }

    public boolean isNoOp(AppealRecord existing, AppealRecord incoming, UpdateIntent intent) {
        if (incoming == null) {
            return true;
        }
        return switch (intent) {
            case FULL_UPDATE, PARTIAL_UPDATE -> !hasBusinessFieldMutation(existing, incoming);
            case WORKFLOW_UPDATE -> !hasWorkflowFieldMutation(existing, incoming);
            case SYSTEM_UPDATE -> !hasSystemFieldMutation(existing, incoming);
        };
    }

    public boolean isStaleUpdate(AppealRecord existing, AppealRecord incoming) {
        return existing != null
                && incoming != null
                && existing.getUpdatedAt() != null
                && incoming.getUpdatedAt() != null
                && incoming.getUpdatedAt().isBefore(existing.getUpdatedAt());
    }

    private boolean hasBusinessFieldMutation(AppealRecord existing, AppealRecord incoming) {
        return changed(existing, incoming, AppealRecord::getAppellantName)
                || changed(existing, incoming, AppealRecord::getAppellantIdCard)
                || changed(existing, incoming, AppealRecord::getAppellantContact)
                || changed(existing, incoming, AppealRecord::getAppellantEmail)
                || changed(existing, incoming, AppealRecord::getAppellantAddress)
                || changed(existing, incoming, AppealRecord::getAppealType)
                || changed(existing, incoming, AppealRecord::getAppealReason)
                || changed(existing, incoming, AppealRecord::getEvidenceDescription)
                || changed(existing, incoming, AppealRecord::getEvidenceUrls)
                || changed(existing, incoming, AppealRecord::getRemarks);
    }

    private boolean hasWorkflowFieldMutation(AppealRecord existing, AppealRecord incoming) {
        return changed(existing, incoming, AppealRecord::getProcessStatus)
                || changed(existing, incoming, AppealRecord::getProcessTime)
                || changed(existing, incoming, AppealRecord::getProcessResult)
                || changed(existing, incoming, AppealRecord::getProcessHandler);
    }

    private boolean hasSystemFieldMutation(AppealRecord existing, AppealRecord incoming) {
        return hasWorkflowFieldMutation(existing, incoming)
                || changed(existing, incoming, AppealRecord::getAcceptanceStatus)
                || changed(existing, incoming, AppealRecord::getAcceptanceTime)
                || changed(existing, incoming, AppealRecord::getAcceptanceHandler)
                || changed(existing, incoming, AppealRecord::getRejectionReason)
                || changed(existing, incoming, AppealRecord::getCreatedAt)
                || changed(existing, incoming, AppealRecord::getUpdatedAt)
                || changed(existing, incoming, AppealRecord::getCreatedBy)
                || changed(existing, incoming, AppealRecord::getUpdatedBy)
                || changed(existing, incoming, AppealRecord::getDeletedAt);
    }

    private boolean changed(
            AppealRecord existing,
            AppealRecord incoming,
            Function<AppealRecord, ?> accessor
    ) {
        if (existing == null || incoming == null) {
            return false;
        }
        Object incomingValue = accessor.apply(incoming);
        return incomingValue != null && !Objects.equals(accessor.apply(existing), incomingValue);
    }
}
