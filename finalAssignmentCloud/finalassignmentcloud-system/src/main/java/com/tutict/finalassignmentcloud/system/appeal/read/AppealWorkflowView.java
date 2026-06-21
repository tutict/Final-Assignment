package com.tutict.finalassignmentcloud.system.appeal.read;

import java.time.LocalDateTime;

public record AppealWorkflowView(
        Long appealId,
        String acceptanceStatus,
        LocalDateTime acceptanceTime,
        String rejectionReason,
        String processStatus,
        LocalDateTime processTime,
        String processResult
) {
}
