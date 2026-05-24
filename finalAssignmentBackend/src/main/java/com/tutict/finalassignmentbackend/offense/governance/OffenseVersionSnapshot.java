package com.tutict.finalassignmentbackend.offense.governance;

import com.tutict.finalassignmentbackend.entity.offense.OffenseRecord;

import java.time.LocalDateTime;

public record OffenseVersionSnapshot(
        LocalDateTime updatedAt,
        LocalDateTime processTime,
        String processStatus,
        LocalDateTime notificationTime,
        SemanticEventType semanticEventType
) {

    public static OffenseVersionSnapshot from(OffenseRecord record, SemanticEventType semanticEventType) {
        if (record == null) {
            return new OffenseVersionSnapshot(null, null, null, null, semanticEventType);
        }
        return new OffenseVersionSnapshot(
                record.getUpdatedAt(),
                record.getProcessTime(),
                record.getProcessStatus(),
                record.getNotificationTime(),
                semanticEventType
        );
    }
}
