package com.tutict.finalassignmentbackend.appeal.domain.policy;

public record AppealCallerMetadata(
        AppealCallerType callerType,
        String source
) {
    public static AppealCallerMetadata controller(String source) {
        return new AppealCallerMetadata(AppealCallerType.CONTROLLER, source);
    }

    public static AppealCallerMetadata workflow(String source) {
        return new AppealCallerMetadata(AppealCallerType.WORKFLOW, source);
    }

    public static AppealCallerMetadata system(String source) {
        return new AppealCallerMetadata(AppealCallerType.SYSTEM, source);
    }

    public static AppealCallerMetadata unknown() {
        return new AppealCallerMetadata(AppealCallerType.UNKNOWN, "unknown");
    }
}
