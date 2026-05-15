package com.tutict.finalassignmentbackend.service.events;

import java.time.LocalDateTime;

public record AppealStatusChangedEvent(
        String applicantUserId,
        Long appealId,
        String newStatus,
        LocalDateTime updatedAt
) {
}
