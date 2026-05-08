package com.tutict.finalassignmentbackend.appeal.domain;

import com.tutict.finalassignmentbackend.appeal.domain.policy.AppealCallerIntentPolicy;
import com.tutict.finalassignmentbackend.appeal.domain.policy.AppealCallerMetadata;
import com.tutict.finalassignmentbackend.appeal.domain.policy.AppealUpdateIntentPolicy;
import com.tutict.finalassignmentbackend.appeal.domain.policy.AppealUpdateIntentPolicy.UpdateIntent;
import com.tutict.finalassignmentbackend.appeal.domain.policy.AppealWorkflowDecisionPolicy;
import com.tutict.finalassignmentbackend.config.statemachine.states.AppealProcessState;
import com.tutict.finalassignmentbackend.entity.AppealRecord;
import org.springframework.stereotype.Service;

import java.util.Objects;

@Service
public class AppealUpdateMergeCoordinator {

    private final AppealFieldMergeService fieldMergeService;
    private final AppealUpdateIntentPolicy intentPolicy;
    private final AppealCallerIntentPolicy callerIntentPolicy;
    private final AppealWorkflowDecisionPolicy workflowDecisionPolicy;

    public AppealUpdateMergeCoordinator() {
        this(
                new AppealFieldMergeService(),
                new AppealUpdateIntentPolicy(),
                new AppealCallerIntentPolicy(),
                new AppealWorkflowDecisionPolicy()
        );
    }

    public AppealUpdateMergeCoordinator(
            AppealFieldMergeService fieldMergeService,
            AppealUpdateIntentPolicy intentPolicy,
            AppealCallerIntentPolicy callerIntentPolicy,
            AppealWorkflowDecisionPolicy workflowDecisionPolicy
    ) {
        this.fieldMergeService = fieldMergeService;
        this.intentPolicy = intentPolicy;
        this.callerIntentPolicy = callerIntentPolicy;
        this.workflowDecisionPolicy = workflowDecisionPolicy;
    }

    public AppealRecord merge(AppealRecord existing, AppealRecord incoming, UpdateIntent intent) {
        return merge(existing, incoming, intent, AppealCallerMetadata.unknown());
    }

    public AppealRecord merge(
            AppealRecord existing,
            AppealRecord incoming,
            UpdateIntent intent,
            AppealCallerMetadata callerMetadata
    ) {
        Objects.requireNonNull(existing, "Existing appeal record cannot be null");
        Objects.requireNonNull(incoming, "Incoming appeal record cannot be null");
        callerIntentPolicy.validate(callerMetadata, intent);
        intentPolicy.validateIntent(existing, incoming, intent);
        return switch (intent) {
            case FULL_UPDATE, PARTIAL_UPDATE -> fieldMergeService.merge(existing, incoming);
            case WORKFLOW_UPDATE -> mergeWorkflow(existing, incoming);
            case SYSTEM_UPDATE -> mergeSystem(existing, incoming);
        };
    }

    public boolean isNoOp(AppealRecord existing, AppealRecord incoming, UpdateIntent intent) {
        return intentPolicy.isNoOp(existing, incoming, intent);
    }

    private AppealRecord mergeWorkflow(AppealRecord existing, AppealRecord incoming) {
        AppealRecord merged = copyExisting(existing);
        AppealProcessState requestedState = resolveIncomingWorkflowState(incoming);
        merged.setProcessStatus(workflowDecisionPolicy.resolveProcessStatus(requestedState, existing.getProcessStatus()));
        return merged;
    }

    private AppealRecord mergeSystem(AppealRecord existing, AppealRecord incoming) {
        AppealRecord merged = copyExisting(existing);
        if (incoming.getAcceptanceStatus() != null) {
            merged.setAcceptanceStatus(incoming.getAcceptanceStatus());
        }
        if (incoming.getAcceptanceTime() != null) {
            merged.setAcceptanceTime(incoming.getAcceptanceTime());
        }
        if (incoming.getAcceptanceHandler() != null) {
            merged.setAcceptanceHandler(incoming.getAcceptanceHandler());
        }
        if (incoming.getRejectionReason() != null) {
            merged.setRejectionReason(incoming.getRejectionReason());
        }
        if (incoming.getProcessStatus() != null) {
            merged.setProcessStatus(incoming.getProcessStatus());
        }
        if (incoming.getProcessTime() != null) {
            merged.setProcessTime(incoming.getProcessTime());
        }
        if (incoming.getProcessResult() != null) {
            merged.setProcessResult(incoming.getProcessResult());
        }
        if (incoming.getProcessHandler() != null) {
            merged.setProcessHandler(incoming.getProcessHandler());
        }
        if (incoming.getUpdatedAt() != null) {
            merged.setUpdatedAt(incoming.getUpdatedAt());
        }
        if (incoming.getUpdatedBy() != null) {
            merged.setUpdatedBy(incoming.getUpdatedBy());
        }
        return merged;
    }

    private AppealRecord copyExisting(AppealRecord existing) {
        AppealRecord incoming = new AppealRecord();
        incoming.setAppealId(existing.getAppealId());
        return fieldMergeService.merge(existing, incoming);
    }

    private AppealProcessState resolveIncomingWorkflowState(AppealRecord incoming) {
        if (incoming.getProcessStatus() == null) {
            return null;
        }
        AppealProcessState state = AppealProcessState.fromCode(incoming.getProcessStatus());
        if (state == null) {
            throw new IllegalStateException("Invalid appeal workflow status: " + incoming.getProcessStatus());
        }
        return state;
    }
}
