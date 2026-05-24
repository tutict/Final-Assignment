package com.tutict.finalassignmentbackend.appeal.domain.policy;

import com.tutict.finalassignmentbackend.entity.appeal.AppealRecord;

import java.util.Objects;
import java.util.function.Function;

public class AppealEventIntentPolicy {

    public AppealEventMetadata classify(
            String action,
            AppealRecord existing,
            AppealRecord incoming,
            boolean duplicate
    ) {
        if (duplicate) {
            return AppealEventMetadata.noOp(true);
        }
        if (isCreate(action)) {
            return AppealEventMetadata.fullUpdate();
        }
        if (incoming == null || existing == null) {
            return AppealEventMetadata.fullUpdate();
        }

        boolean workflowMutation = hasWorkflowFieldMutation(existing, incoming);
        boolean systemMutation = hasSystemFieldMutation(existing, incoming);
        boolean businessMutation = hasBusinessFieldMutation(existing, incoming);

        if (!workflowMutation && !systemMutation && !businessMutation) {
            return AppealEventMetadata.noOp(false);
        }
        if (workflowMutation) {
            return AppealEventMetadata.workflow();
        }
        if (businessMutation) {
            return AppealEventMetadata.fullUpdate();
        }
        return systemMutation ? AppealEventMetadata.system() : AppealEventMetadata.fullUpdate();
    }

    private boolean isCreate(String action) {
        return "create".equalsIgnoreCase(action);
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
        return changed(existing, incoming, AppealRecord::getAcceptanceStatus)
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
        Object incomingValue = accessor.apply(incoming);
        return incomingValue != null && !Objects.equals(accessor.apply(existing), incomingValue);
    }
}
