package com.tutict.finalassignmentcloud.system.appeal.domain.policy;

import com.tutict.finalassignmentcloud.system.appeal.domain.policy.AppealUpdateIntentPolicy.UpdateIntent;

public class AppealCallerIntentPolicy {

    public void validate(AppealCallerMetadata callerMetadata, UpdateIntent requestedIntent) {
        if (callerMetadata == null
                || callerMetadata.callerType() == null
                || callerMetadata.callerType() == AppealCallerType.UNKNOWN) {
            throw new IllegalStateException("Unknown appeal update caller");
        }
        if (requestedIntent == null) {
            throw new IllegalArgumentException("Appeal update intent cannot be null");
        }
        if (!isAllowed(callerMetadata.callerType(), requestedIntent)) {
            throw new IllegalStateException("Appeal caller intent mismatch: "
                    + callerMetadata.callerType() + " cannot execute " + requestedIntent);
        }
    }

    private boolean isAllowed(AppealCallerType callerType, UpdateIntent requestedIntent) {
        return switch (callerType) {
            case CONTROLLER -> requestedIntent == UpdateIntent.FULL_UPDATE;
            case WORKFLOW -> requestedIntent == UpdateIntent.WORKFLOW_UPDATE;
            case SYSTEM -> requestedIntent == UpdateIntent.SYSTEM_UPDATE;
            case UNKNOWN -> false;
        };
    }
}
