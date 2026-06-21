package com.tutict.finalassignmentcloud.offense.governance;

import java.util.Set;

public final class OffenseFieldMergePolicy {

    public enum FieldCategory {
        BUSINESS_FIELDS,
        WORKFLOW_FIELDS,
        SYSTEM_FIELDS,
        IMMUTABLE_FIELDS,
        UNKNOWN
    }

    private static final Set<String> BUSINESS_FIELDS = Set.of(
            "offenseCode",
            "offenseTime",
            "offenseLocation",
            "offenseProvince",
            "offenseCity",
            "driverId",
            "vehicleId",
            "offenseDescription",
            "evidenceType",
            "evidenceUrls",
            "enforcementAgency",
            "enforcementOfficer",
            "enforcementDevice",
            "fineAmount",
            "deductedPoints",
            "detentionDays",
            "remarks"
    );

    private static final Set<String> WORKFLOW_FIELDS = Set.of(
            "processStatus",
            "processTime",
            "processHandler",
            "processResult",
            "updatedAt"
    );

    private static final Set<String> SYSTEM_FIELDS = Set.of(
            "notificationStatus",
            "notificationTime",
            "createdAt",
            "createdBy",
            "updatedBy",
            "deletedAt"
    );

    private static final Set<String> IMMUTABLE_FIELDS = Set.of(
            "offenseId",
            "offenseNumber"
    );

    public FieldCategory categoryOf(String fieldName) {
        if (BUSINESS_FIELDS.contains(fieldName)) {
            return FieldCategory.BUSINESS_FIELDS;
        }
        if (WORKFLOW_FIELDS.contains(fieldName)) {
            return FieldCategory.WORKFLOW_FIELDS;
        }
        if (SYSTEM_FIELDS.contains(fieldName)) {
            return FieldCategory.SYSTEM_FIELDS;
        }
        if (IMMUTABLE_FIELDS.contains(fieldName)) {
            return FieldCategory.IMMUTABLE_FIELDS;
        }
        return FieldCategory.UNKNOWN;
    }

    public boolean canOverwrite(SemanticEventType eventType, String fieldName) {
        return canOverwrite(eventType, categoryOf(fieldName));
    }

    public boolean canOverwrite(SemanticEventType eventType, FieldCategory category) {
        if (eventType == null || category == null) {
            return false;
        }
        return switch (eventType) {
            case FULL_UPDATE -> category == FieldCategory.BUSINESS_FIELDS
                    || category == FieldCategory.SYSTEM_FIELDS;
            case WORKFLOW -> category == FieldCategory.WORKFLOW_FIELDS;
            case SYSTEM -> category == FieldCategory.SYSTEM_FIELDS;
            case NO_OP, UNKNOWN -> false;
        };
    }
}
