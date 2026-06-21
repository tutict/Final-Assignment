package com.tutict.finalassignmentcloud.common.event;

import lombok.Getter;
import org.springframework.context.ApplicationEvent;

import java.time.LocalDateTime;

/**
 * Event published when appeal status changes
 * Used for event-driven processing and audit trails
 */
@Getter
public class AppealStatusChangedEvent extends ApplicationEvent {

    private final Long appealId;
    private final String oldStatus;
    private final String newStatus;
    private final String changedBy;
    private final LocalDateTime changedAt;

    public AppealStatusChangedEvent(Object source,
                                   Long appealId,
                                   String oldStatus,
                                   String newStatus,
                                   String changedBy) {
        super(source);
        this.appealId = appealId;
        this.oldStatus = oldStatus;
        this.newStatus = newStatus;
        this.changedBy = changedBy;
        this.changedAt = LocalDateTime.now();
    }

    @Override
    public String toString() {
        return String.format("AppealStatusChangedEvent[appealId=%d, %s->%s, by=%s, at=%s]",
            appealId, oldStatus, newStatus, changedBy, changedAt);
    }
}
