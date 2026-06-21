package com.tutict.finalassignmentcloud.system.appeal.projection;

import java.time.LocalDateTime;

public record AppealRecordView(
        String sourceKey,
        Long appealId,
        Long offenseId,
        String appealNumber,
        String appellantName,
        String appealType,
        String appealReason,
        LocalDateTime appealTime,
        String acceptanceStatus,
        String processStatus,
        String acceptanceHandler,
        String processHandler
) {
}
