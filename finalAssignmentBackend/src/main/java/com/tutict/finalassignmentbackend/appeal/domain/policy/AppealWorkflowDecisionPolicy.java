package com.tutict.finalassignmentbackend.appeal.domain.policy;

import com.tutict.finalassignmentbackend.config.statemachine.states.AppealProcessState;
import com.tutict.finalassignmentbackend.entity.AppealRecord;
import org.springframework.stereotype.Service;

@Service
public class AppealWorkflowDecisionPolicy {

    public boolean isMissingAppeal(AppealRecord appealRecord) {
        return appealRecord == null;
    }

    public boolean isMissingMutation(int rows) {
        return rows == 0;
    }

    public String resolveProcessStatus(AppealProcessState requestedState, String currentProcessStatus) {
        return requestedState != null ? requestedState.getCode() : currentProcessStatus;
    }
}
