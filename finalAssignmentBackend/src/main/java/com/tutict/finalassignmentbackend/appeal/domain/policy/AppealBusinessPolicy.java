package com.tutict.finalassignmentbackend.appeal.domain.policy;

import com.tutict.finalassignmentbackend.entity.SysRequestHistory;
import org.springframework.stereotype.Service;

@Service
public class AppealBusinessPolicy {

    private static final int FAILURE_REASON_LIMIT = 500;

    public boolean isDuplicateRequest(SysRequestHistory history) {
        return history != null;
    }

    public boolean shouldSkipProcessedRequest(SysRequestHistory history) {
        return history != null
                && "SUCCESS".equalsIgnoreCase(history.getBusinessStatus())
                && "DONE".equalsIgnoreCase(history.getRequestParams());
    }

    public boolean canUpdateHistory(SysRequestHistory history) {
        return history != null;
    }

    public String truncateFailureReason(String reason) {
        if (reason == null) {
            return null;
        }
        return reason.length() <= FAILURE_REASON_LIMIT ? reason : reason.substring(0, FAILURE_REASON_LIMIT);
    }
}
