package com.tutict.finalassignmentbackend.appeal.domain.policy;

import com.tutict.finalassignmentbackend.entity.AppealRecord;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Service
public class AppealQueryPolicy {

    public boolean shouldReturnEmptyForTextFilter(String value) {
        return value == null || value.trim().isEmpty();
    }

    public boolean hasIndexedRecord(Optional<AppealRecord> indexed) {
        return indexed != null && indexed.isPresent();
    }

    public boolean shouldUseDbFallback(List<AppealRecord> indexed) {
        return indexed == null || indexed.isEmpty();
    }

    public boolean shouldReturnEmptyForTimeRange(LocalDateTime start, LocalDateTime end) {
        return start == null || end == null;
    }

    public boolean shouldBackfill(AppealRecord fallback) {
        return fallback != null;
    }

    public boolean shouldBackfill(List<AppealRecord> fallback) {
        return fallback != null && !fallback.isEmpty();
    }
}
