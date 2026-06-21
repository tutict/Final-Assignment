package com.tutict.finalassignmentcloud.system.appeal.domain.policy;

import com.tutict.finalassignmentcloud.entity.appeal.AppealProcessState;
import com.tutict.finalassignmentcloud.entity.appeal.AppealRecord;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

/**
 * Appeal Workflow Decision Policy
 * Determines workflow decisions based on appeal state
 */
@Service
public class AppealWorkflowDecisionPolicy {

    private static final Logger log = LoggerFactory.getLogger(AppealWorkflowDecisionPolicy.class);

    private final AppealTransitionPolicy transitionPolicy = new AppealTransitionPolicy();

    public boolean isMissingAppeal(AppealRecord appealRecord) {
        boolean missing = appealRecord == null;
        if (missing) {
            log.warn("Appeal record is missing (null)");
        }
        return missing;
    }

    public boolean isMissingMutation(int rows) {
        boolean missing = rows == 0;
        if (missing) {
            log.warn("Mutation failed: no rows affected");
        } else {
            log.debug("Mutation successful: {} rows affected", rows);
        }
        return missing;
    }

    public String resolveProcessStatus(AppealProcessState requestedState, String currentProcessStatus) {
        log.debug("Resolving process status: current={}, requested={}",
                 currentProcessStatus, requestedState != null ? requestedState.getCode() : null);

        AppealTransitionPolicy.TransitionDecision decision = transitionPolicy.decide(currentProcessStatus, requestedState);

        if (decision == AppealTransitionPolicy.TransitionDecision.INVALID) {
            log.error("Invalid appeal status transition: {} -> ",
                     currentProcessStatus, requestedState.getCode());
            throw new IllegalStateException("Invalid appeal status transition: "
                    + currentProcessStatus + " -> " + requestedState.getCode());
        }

        String resolvedStatus = decision == AppealTransitionPolicy.TransitionDecision.APPLY
                ? requestedState.getCode()
                : currentProcessStatus;

        log.info("Process status resolved: current={}, requested={}, resolved={}, decision={}",
                currentProcessStatus, requestedState.getCode(), resolvedStatus, decision);

        return resolvedStatus;
    }

    public boolean isTerminalStatus(String processStatus) {
        boolean terminal = transitionPolicy.isTerminal(processStatus);
        log.debug("Checking terminal status: status={}, terminal={}", processStatus, terminal);
        return terminal;
    }
}
