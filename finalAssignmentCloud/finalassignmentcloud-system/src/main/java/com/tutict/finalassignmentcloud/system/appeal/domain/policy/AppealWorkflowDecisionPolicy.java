package com.tutict.finalassignmentcloud.system.appeal.domain.policy;

import com.tutict.finalassignmentbackend.config.statemachine.states.AppealProcessState;
import com.tutict.finalassignmentcloud.entity.appeal.AppealRecord;
import org.springframework.stereotype.Service;

@Service
public class AppealWorkflowDecisionPolicy {

    private final AppealTransitionPolicy transitionPolicy = new AppealTransitionPolicy();

    public boolean isMissingAppeal(AppealRecord appealRecord) {
        return appealRecord == null;
    }

    public boolean isMissingMutation(int rows) {
        return rows == 0;
    }

    public String resolveProcessStatus(AppealProcessState requestedState, String currentProcessStatus) {
        AppealTransitionPolicy.TransitionDecision decision = transitionPolicy.decide(currentProcessStatus, requestedState);
        if (decision == AppealTransitionPolicy.TransitionDecision.INVALID) {
            throw new IllegalStateException("Invalid appeal status transition: "
                    + currentProcessStatus + " -> " + requestedState.getCode());
        }
        return decision == AppealTransitionPolicy.TransitionDecision.APPLY
                ? requestedState.getCode()
                : currentProcessStatus;
    }

    public boolean isTerminalStatus(String processStatus) {
        return transitionPolicy.isTerminal(processStatus);
    }
}
