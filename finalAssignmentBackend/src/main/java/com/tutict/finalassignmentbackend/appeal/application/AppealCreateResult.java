package com.tutict.finalassignmentbackend.appeal.application;

import com.tutict.finalassignmentbackend.entity.appeal.AppealRecord;

/** Result of a keyed appeal create, including an idempotent no-op. */
public record AppealCreateResult(AppealRecord appeal, boolean duplicate) {

    public static AppealCreateResult created(AppealRecord appeal) {
        return new AppealCreateResult(appeal, false);
    }

    public static AppealCreateResult alreadyProcessed() {
        return new AppealCreateResult(null, true);
    }
}
