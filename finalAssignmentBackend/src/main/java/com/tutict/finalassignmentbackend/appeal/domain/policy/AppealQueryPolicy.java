package com.tutict.finalassignmentbackend.appeal.domain.policy;

import com.tutict.finalassignmentbackend.entity.appeal.AppealRecord;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Service
public class AppealQueryPolicy {

    private final AppealVisibilityPolicy visibilityPolicy = new AppealVisibilityPolicy();

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

    public AppealVisibilityPolicy.AppealVisibilityContext defaultVisibility() {
        return AppealVisibilityPolicy.AppealVisibilityContext.unrestricted();
    }

    public AppealVisibilityPolicy.AppealVisibilityContext offenseVisibility(Long offenseId) {
        return AppealVisibilityPolicy.AppealVisibilityContext.forOffense(offenseId);
    }

    public Optional<AppealRecord> visibleRecord(
            Optional<AppealRecord> record,
            AppealVisibilityPolicy.AppealVisibilityContext context
    ) {
        return record == null ? Optional.empty() : record.filter(value -> visibilityPolicy.isVisible(value, context));
    }

    public AppealRecord visibleRecord(
            AppealRecord record,
            AppealVisibilityPolicy.AppealVisibilityContext context
    ) {
        return visibilityPolicy.isVisible(record, context) ? record : null;
    }

    public List<AppealRecord> visibleRecords(
            List<AppealRecord> records,
            AppealVisibilityPolicy.AppealVisibilityContext context
    ) {
        return visibilityPolicy.filterVisible(records, context);
    }
}
