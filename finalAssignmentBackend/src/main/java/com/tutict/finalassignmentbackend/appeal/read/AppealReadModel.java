package com.tutict.finalassignmentbackend.appeal.read;

import java.time.LocalDateTime;

public record AppealReadModel(
        Long appealId,
        Long offenseId,
        String appealNumber,
        String appellantName,
        String appellantIdCard,
        String appellantContact,
        String appellantEmail,
        String appellantAddress,
        String appealType,
        String appealReason,
        LocalDateTime appealTime,
        String evidenceDescription,
        String evidenceUrls,
        String acceptanceStatus,
        LocalDateTime acceptanceTime,
        String acceptanceHandler,
        String rejectionReason,
        String processStatus,
        LocalDateTime processTime,
        String processResult,
        String processHandler,
        LocalDateTime createdAt,
        LocalDateTime updatedAt,
        String createdBy,
        String updatedBy,
        LocalDateTime deletedAt,
        String remarks
) {
    public String sourceKey() {
        return appealId == null ? null : "appeal_record:" + appealId;
    }
}
