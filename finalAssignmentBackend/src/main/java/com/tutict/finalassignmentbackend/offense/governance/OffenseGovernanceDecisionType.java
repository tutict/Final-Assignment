package com.tutict.finalassignmentbackend.offense.governance;

public enum OffenseGovernanceDecisionType {
    STALE_REJECTED,
    SHADOW_STALE,
    NO_OP_SUPPRESSED,
    NULL_FIELD_PRESERVED,
    IMMUTABLE_FIELD_PRESERVED,
    WORKFLOW_FIELD_SUPPRESSED,
    LEGACY_COMPATIBILITY_MODE,
    READ_REPAIR_TRIGGERED
}
