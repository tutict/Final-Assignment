package com.tutict.finalassignmentbackend.service.events;

import java.time.LocalDateTime;

public record PaymentStatusChangedEvent(
        String payerUserId,
        Long paymentId,
        Long fineId,
        String newStatus,
        LocalDateTime updatedAt
) {
}
