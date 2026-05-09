package com.tutict.finalassignmentbackend.offense.governance.rollout;

import com.tutict.finalassignmentbackend.offense.governance.OffenseGovernanceDecisionType;
import com.tutict.finalassignmentbackend.offense.governance.OffenseGovernanceLogFactory;
import com.tutict.finalassignmentbackend.offense.governance.SemanticEventType;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

class GovernanceRolloutPolicyTest {

    private final GovernanceRolloutPolicy policy = new GovernanceRolloutPolicy();

    @Test
    void kafkaFullUpdateDefaultsToEnforcedRollout() {
        assertThat(policy.currentRolloutMode(GovernanceSourceType.KAFKA, SemanticEventType.FULL_UPDATE))
                .isEqualTo(GovernanceRolloutMode.ENFORCED);
        assertThat(policy.shouldRejectStale(GovernanceSourceType.KAFKA, SemanticEventType.FULL_UPDATE)).isTrue();
        assertThat(policy.shouldPreserveNulls(GovernanceSourceType.KAFKA, SemanticEventType.FULL_UPDATE)).isTrue();
        assertThat(policy.shouldSuppressWorkflowOverwrite(GovernanceSourceType.KAFKA, SemanticEventType.FULL_UPDATE)).isTrue();
    }

    @Test
    void controllerFullUpdateDefaultsToShadowStaleAndCompatibilityMerge() {
        assertThat(policy.currentRolloutMode(GovernanceSourceType.CONTROLLER, SemanticEventType.FULL_UPDATE))
                .isEqualTo(GovernanceRolloutMode.SHADOW);
        assertThat(policy.mergeRolloutMode(GovernanceSourceType.CONTROLLER, SemanticEventType.FULL_UPDATE))
                .isEqualTo(GovernanceRolloutMode.COMPATIBILITY);
        assertThat(policy.shouldRejectStale(GovernanceSourceType.CONTROLLER, SemanticEventType.FULL_UPDATE)).isFalse();
        assertThat(policy.shouldShadowLog(GovernanceSourceType.CONTROLLER, SemanticEventType.FULL_UPDATE)).isTrue();
        assertThat(policy.shouldPreserveNulls(GovernanceSourceType.CONTROLLER, SemanticEventType.FULL_UPDATE)).isTrue();
    }

    @Test
    void workflowStaleProtectionDefaultsToEnforcedRollout() {
        assertThat(policy.currentRolloutMode(GovernanceSourceType.WORKFLOW, SemanticEventType.WORKFLOW))
                .isEqualTo(GovernanceRolloutMode.ENFORCED);
        assertThat(policy.shouldRejectStale(GovernanceSourceType.WORKFLOW, SemanticEventType.WORKFLOW)).isTrue();
    }

    @Test
    void queryRepairDefaultsToLegacyInformationalVisibility() {
        assertThat(policy.currentRolloutMode(GovernanceSourceType.QUERY_REPAIR, SemanticEventType.SYSTEM))
                .isEqualTo(GovernanceRolloutMode.LEGACY);
        assertThat(policy.shouldRejectStale(GovernanceSourceType.QUERY_REPAIR, SemanticEventType.SYSTEM)).isFalse();

        assertThat(OffenseGovernanceLogFactory.format(OffenseGovernanceLogFactory.readRepairTriggered(10L, 1)))
                .contains("rolloutMode=LEGACY")
                .contains("source=QUERY_REPAIR")
                .contains("semantic=SYSTEM");
    }

    @Test
    void decisionRolloutModeSeparatesShadowFromCompatibilityFallback() {
        assertThat(policy.rolloutModeForDecision(
                GovernanceSourceType.CONTROLLER,
                SemanticEventType.FULL_UPDATE,
                OffenseGovernanceDecisionType.SHADOW_STALE
        )).isEqualTo(GovernanceRolloutMode.SHADOW);
        assertThat(policy.rolloutModeForDecision(
                GovernanceSourceType.CONTROLLER,
                SemanticEventType.FULL_UPDATE,
                OffenseGovernanceDecisionType.NULL_FIELD_PRESERVED
        )).isEqualTo(GovernanceRolloutMode.COMPATIBILITY);
        assertThat(policy.rolloutModeForDecision(
                GovernanceSourceType.KAFKA,
                SemanticEventType.FULL_UPDATE,
                OffenseGovernanceDecisionType.NULL_FIELD_PRESERVED,
                true
        )).isEqualTo(GovernanceRolloutMode.COMPATIBILITY);
    }
}
