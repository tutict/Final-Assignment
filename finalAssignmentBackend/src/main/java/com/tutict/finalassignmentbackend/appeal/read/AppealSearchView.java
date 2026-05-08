package com.tutict.finalassignmentbackend.appeal.read;

import java.time.LocalDateTime;

public record AppealSearchView(
        String sourceKey,
        Long appealId,
        Long offenseId,
        String appealNumber,
        String appellantName,
        String appealType,
        String appealReason,
        LocalDateTime appealTime,
        String acceptanceStatus,
        String processStatus
) {
}
