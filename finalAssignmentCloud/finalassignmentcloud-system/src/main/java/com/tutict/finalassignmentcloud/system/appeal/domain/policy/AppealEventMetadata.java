package com.tutict.finalassignmentcloud.system.appeal.domain.policy;

import com.tutict.finalassignmentcloud.system.appeal.domain.policy.AppealUpdateIntentPolicy.UpdateIntent;

public record AppealEventMetadata(
        AppealEventType eventType,
        UpdateIntent updateIntent,
        boolean duplicate,
        boolean mutatesDatabase,
        boolean reindexesSearch,
        boolean evictsCache,
        boolean republishesKafka,
        boolean requiresAfterCommit
) {
    public static AppealEventMetadata fullUpdate() {
        return mutating(AppealEventType.FULL_UPDATE, UpdateIntent.FULL_UPDATE, false);
    }

    public static AppealEventMetadata outboundFullUpdate() {
        return mutating(AppealEventType.FULL_UPDATE, UpdateIntent.FULL_UPDATE, true);
    }

    public static AppealEventMetadata workflow() {
        return mutating(AppealEventType.WORKFLOW, UpdateIntent.WORKFLOW_UPDATE, false);
    }

    public static AppealEventMetadata system() {
        return mutating(AppealEventType.SYSTEM, UpdateIntent.SYSTEM_UPDATE, false);
    }

    public static AppealEventMetadata noOp(boolean duplicate) {
        return new AppealEventMetadata(
                AppealEventType.NO_OP,
                null,
                duplicate,
                false,
                false,
                false,
                false,
                false
        );
    }

    public boolean noOp() {
        return eventType == AppealEventType.NO_OP;
    }

    private static AppealEventMetadata mutating(
            AppealEventType eventType,
            UpdateIntent updateIntent,
            boolean republishesKafka
    ) {
        return new AppealEventMetadata(
                eventType,
                updateIntent,
                false,
                true,
                true,
                true,
                republishesKafka,
                true
        );
    }
}
