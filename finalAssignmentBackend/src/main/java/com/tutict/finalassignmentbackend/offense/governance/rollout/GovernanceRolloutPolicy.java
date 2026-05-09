package com.tutict.finalassignmentbackend.offense.governance.rollout;

import com.tutict.finalassignmentbackend.offense.governance.OffenseGovernanceDecisionType;
import com.tutict.finalassignmentbackend.offense.governance.SemanticEventType;

public final class GovernanceRolloutPolicy {

    public GovernanceRolloutMode currentRolloutMode(GovernanceSourceType sourceType,
                                                    SemanticEventType semanticEventType) {
        if (sourceType == null || semanticEventType == null) {
            return GovernanceRolloutMode.LEGACY;
        }
        return switch (sourceType) {
            case KAFKA -> kafkaMode(semanticEventType);
            case CONTROLLER -> controllerMode(semanticEventType);
            case WORKFLOW -> workflowMode(semanticEventType);
            case QUERY_REPAIR -> GovernanceRolloutMode.LEGACY;
        };
    }

    public GovernanceRolloutMode mergeRolloutMode(GovernanceSourceType sourceType,
                                                  SemanticEventType semanticEventType) {
        if (semanticEventType != SemanticEventType.FULL_UPDATE) {
            return currentRolloutMode(sourceType, semanticEventType);
        }
        if (sourceType == GovernanceSourceType.KAFKA) {
            return GovernanceRolloutMode.ENFORCED;
        }
        if (sourceType == GovernanceSourceType.CONTROLLER) {
            return GovernanceRolloutMode.COMPATIBILITY;
        }
        return currentRolloutMode(sourceType, semanticEventType);
    }

    public GovernanceRolloutMode rolloutModeForDecision(GovernanceSourceType sourceType,
                                                        SemanticEventType semanticEventType,
                                                        OffenseGovernanceDecisionType decisionType) {
        return rolloutModeForDecision(sourceType, semanticEventType, decisionType, false);
    }

    public GovernanceRolloutMode rolloutModeForDecision(GovernanceSourceType sourceType,
                                                        SemanticEventType semanticEventType,
                                                        OffenseGovernanceDecisionType decisionType,
                                                        boolean compatibilityFallback) {
        if (compatibilityFallback) {
            return GovernanceRolloutMode.COMPATIBILITY;
        }
        if (decisionType == null) {
            return currentRolloutMode(sourceType, semanticEventType);
        }
        return switch (decisionType) {
            case NULL_FIELD_PRESERVED,
                    IMMUTABLE_FIELD_PRESERVED,
                    WORKFLOW_FIELD_SUPPRESSED,
                    LEGACY_COMPATIBILITY_MODE -> mergeRolloutMode(sourceType, semanticEventType);
            default -> currentRolloutMode(sourceType, semanticEventType);
        };
    }

    public boolean shouldRejectStale(GovernanceSourceType sourceType,
                                     SemanticEventType semanticEventType) {
        return currentRolloutMode(sourceType, semanticEventType) == GovernanceRolloutMode.ENFORCED
                && (semanticEventType == SemanticEventType.FULL_UPDATE
                || semanticEventType == SemanticEventType.WORKFLOW);
    }

    public boolean shouldShadowLog(GovernanceSourceType sourceType,
                                   SemanticEventType semanticEventType) {
        GovernanceRolloutMode mode = currentRolloutMode(sourceType, semanticEventType);
        return mode == GovernanceRolloutMode.SHADOW || mode == GovernanceRolloutMode.COMPATIBILITY;
    }

    public boolean shouldPreserveNulls(GovernanceSourceType sourceType,
                                       SemanticEventType semanticEventType) {
        GovernanceRolloutMode mode = mergeRolloutMode(sourceType, semanticEventType);
        return semanticEventType == SemanticEventType.FULL_UPDATE
                && (mode == GovernanceRolloutMode.COMPATIBILITY || mode == GovernanceRolloutMode.ENFORCED);
    }

    public boolean shouldPreserveImmutableFields(GovernanceSourceType sourceType,
                                                 SemanticEventType semanticEventType) {
        return shouldPreserveNulls(sourceType, semanticEventType);
    }

    public boolean shouldSuppressWorkflowOverwrite(GovernanceSourceType sourceType,
                                                   SemanticEventType semanticEventType) {
        return shouldPreserveNulls(sourceType, semanticEventType);
    }

    private GovernanceRolloutMode kafkaMode(SemanticEventType semanticEventType) {
        return switch (semanticEventType) {
            case FULL_UPDATE, NO_OP -> GovernanceRolloutMode.ENFORCED;
            default -> GovernanceRolloutMode.LEGACY;
        };
    }

    private GovernanceRolloutMode controllerMode(SemanticEventType semanticEventType) {
        return semanticEventType == SemanticEventType.FULL_UPDATE
                ? GovernanceRolloutMode.SHADOW
                : GovernanceRolloutMode.LEGACY;
    }

    private GovernanceRolloutMode workflowMode(SemanticEventType semanticEventType) {
        return semanticEventType == SemanticEventType.WORKFLOW
                ? GovernanceRolloutMode.ENFORCED
                : GovernanceRolloutMode.LEGACY;
    }
}
