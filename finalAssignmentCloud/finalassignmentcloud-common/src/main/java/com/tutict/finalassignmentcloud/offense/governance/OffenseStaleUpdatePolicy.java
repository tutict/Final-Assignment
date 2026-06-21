package com.tutict.finalassignmentcloud.offense.governance;

import com.tutict.finalassignmentcloud.entity.offense.OffenseProcessState;

import java.time.LocalDateTime;

public final class OffenseStaleUpdatePolicy {

    public enum Decision {
        ACCEPT,
        REJECT_STALE,
        SHADOW_ONLY
    }

    public Decision decide(OffenseVersionSnapshot current, OffenseVersionSnapshot incoming) {
        if (incoming == null) {
            return Decision.ACCEPT;
        }
        SemanticEventType eventType = incoming.semanticEventType();
        if (eventType == null) {
            return Decision.SHADOW_ONLY;
        }

        return switch (eventType) {
            case WORKFLOW -> decideWorkflow(current, incoming);
            case FULL_UPDATE -> isBefore(incoming.updatedAt(), currentUpdatedAt(current))
                    ? Decision.SHADOW_ONLY
                    : Decision.ACCEPT;
            case SYSTEM -> isBefore(incoming.notificationTime(), currentNotificationTime(current))
                    || isBefore(incoming.updatedAt(), currentUpdatedAt(current))
                    ? Decision.SHADOW_ONLY
                    : Decision.ACCEPT;
            case NO_OP -> Decision.ACCEPT;
            case UNKNOWN -> Decision.SHADOW_ONLY;
        };
    }

    private Decision decideWorkflow(OffenseVersionSnapshot current, OffenseVersionSnapshot incoming) {
        if (isBefore(incoming.processTime(), currentProcessTime(current))) {
            return Decision.REJECT_STALE;
        }
        if (workflowRank(incoming.processStatus()) < workflowRank(currentProcessStatus(current))) {
            return Decision.REJECT_STALE;
        }
        return Decision.ACCEPT;
    }

    private boolean isBefore(LocalDateTime incoming, LocalDateTime current) {
        return incoming != null && current != null && incoming.isBefore(current);
    }

    private LocalDateTime currentUpdatedAt(OffenseVersionSnapshot current) {
        return current == null ? null : current.updatedAt();
    }

    private LocalDateTime currentProcessTime(OffenseVersionSnapshot current) {
        return current == null ? null : current.processTime();
    }

    private String currentProcessStatus(OffenseVersionSnapshot current) {
        return current == null ? null : current.processStatus();
    }

    private LocalDateTime currentNotificationTime(OffenseVersionSnapshot current) {
        return current == null ? null : current.notificationTime();
    }

    private int workflowRank(String status) {
        OffenseProcessState state = OffenseProcessState.fromCode(status);
        if (state == null) {
            return 0;
        }
        return switch (state) {
            case UNPROCESSED -> 0;
            case PROCESSING -> 1;
            case PROCESSED -> 2;
            case APPEALING -> 3;
            case APPEAL_APPROVED, APPEAL_REJECTED, CANCELLED -> 4;
        };
    }
}
