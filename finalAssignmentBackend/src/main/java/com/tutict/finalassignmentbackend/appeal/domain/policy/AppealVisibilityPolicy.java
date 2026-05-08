package com.tutict.finalassignmentbackend.appeal.domain.policy;

import com.tutict.finalassignmentbackend.entity.AppealRecord;

import java.util.List;

public class AppealVisibilityPolicy {

    public record AppealVisibilityContext(
            Long offenseId,
            boolean includeDeleted
    ) {
        public static AppealVisibilityContext unrestricted() {
            return new AppealVisibilityContext(null, false);
        }

        public static AppealVisibilityContext forOffense(Long offenseId) {
            return new AppealVisibilityContext(offenseId, false);
        }
    }

    public boolean isVisible(AppealRecord record, AppealVisibilityContext context) {
        if (record == null) {
            return false;
        }
        AppealVisibilityContext safeContext = context == null ? AppealVisibilityContext.unrestricted() : context;
        if (!safeContext.includeDeleted() && record.getDeletedAt() != null) {
            return false;
        }
        return safeContext.offenseId() == null || safeContext.offenseId().equals(record.getOffenseId());
    }

    public List<AppealRecord> filterVisible(List<AppealRecord> records, AppealVisibilityContext context) {
        if (records == null || records.isEmpty()) {
            return List.of();
        }
        List<AppealRecord> visible = records.stream()
                .filter(record -> isVisible(record, context))
                .toList();
        return visible.size() == records.size() ? records : visible;
    }
}
