package com.tutict.finalassignmentbackend.appeal.domain.policy;

import com.tutict.finalassignmentbackend.config.statemachine.states.AppealProcessState;
import com.tutict.finalassignmentbackend.entity.AppealRecord;
import com.tutict.finalassignmentbackend.entity.SysRequestHistory;
import org.junit.jupiter.api.Test;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.Set;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class AppealPolicyTest {

    @Test
    void businessPolicyCapturesIdempotencyRules() {
        AppealBusinessPolicy policy = new AppealBusinessPolicy();
        SysRequestHistory done = history("SUCCESS", "DONE");
        SysRequestHistory pending = history("SUCCESS", "PENDING");

        assertThat(policy.isDuplicateRequest(done)).isTrue();
        assertThat(policy.isDuplicateRequest(null)).isFalse();
        assertThat(policy.shouldSkipProcessedRequest(done)).isTrue();
        assertThat(policy.shouldSkipProcessedRequest(pending)).isFalse();
        assertThat(policy.shouldSkipProcessedRequest(null)).isFalse();
        assertThat(policy.canUpdateHistory(done)).isTrue();
        assertThat(policy.canUpdateHistory(null)).isFalse();
    }

    @Test
    void businessPolicyTruncatesFailureReasonWithoutChangingNullOrShortValues() {
        AppealBusinessPolicy policy = new AppealBusinessPolicy();
        String shortReason = "failed";
        String longReason = "x".repeat(501);

        assertThat(policy.truncateFailureReason(null)).isNull();
        assertThat(policy.truncateFailureReason(shortReason)).isEqualTo(shortReason);
        assertThat(policy.truncateFailureReason(longReason)).hasSize(500);
    }

    @Test
    void workflowPolicyCapturesMutationAndStatusDecisionRules() {
        AppealWorkflowDecisionPolicy policy = new AppealWorkflowDecisionPolicy();
        AppealRecord existing = new AppealRecord();

        assertThat(policy.isMissingMutation(0)).isTrue();
        assertThat(policy.isMissingMutation(1)).isFalse();
        assertThat(policy.isMissingAppeal(null)).isTrue();
        assertThat(policy.isMissingAppeal(existing)).isFalse();
        assertThat(policy.resolveProcessStatus(null, "Unprocessed")).isEqualTo("Unprocessed");
        assertThat(policy.resolveProcessStatus(AppealProcessState.APPROVED, "Unprocessed"))
                .isEqualTo(AppealProcessState.APPROVED.getCode());
    }

    @Test
    void transitionPolicyDefinesExplicitLegalityMatrix() {
        AppealTransitionPolicy policy = new AppealTransitionPolicy();

        assertThat(policy.allowedTargets("Unprocessed")).containsExactlyInAnyOrder(
                AppealProcessState.UNDER_REVIEW,
                AppealProcessState.APPROVED,
                AppealProcessState.REJECTED,
                AppealProcessState.WITHDRAWN
        );
        assertThat(policy.allowedTargets("Under_Review")).containsExactlyInAnyOrder(
                AppealProcessState.UNPROCESSED,
                AppealProcessState.APPROVED,
                AppealProcessState.REJECTED,
                AppealProcessState.WITHDRAWN
        );
        assertThat(policy.decide("Unprocessed", AppealProcessState.UNDER_REVIEW))
                .isEqualTo(AppealTransitionPolicy.TransitionDecision.APPLY);
        assertThat(policy.decide("Unprocessed", null))
                .isEqualTo(AppealTransitionPolicy.TransitionDecision.NO_OP);
    }

    @Test
    void transitionPolicyDefinesTerminalStatesAndDuplicateTransitions() {
        AppealTransitionPolicy policy = new AppealTransitionPolicy();
        Set<AppealProcessState> terminalStates = policy.terminalStates();

        assertThat(terminalStates).containsExactlyInAnyOrder(
                AppealProcessState.APPROVED,
                AppealProcessState.REJECTED,
                AppealProcessState.WITHDRAWN
        );
        assertThat(policy.isTerminal("Approved")).isTrue();
        assertThat(policy.isTerminal("Under_Review")).isFalse();
        assertThat(policy.decide("Approved", AppealProcessState.APPROVED))
                .isEqualTo(AppealTransitionPolicy.TransitionDecision.NO_OP);
        assertThat(policy.decide("Approved", AppealProcessState.UNDER_REVIEW))
                .isEqualTo(AppealTransitionPolicy.TransitionDecision.INVALID);
    }

    @Test
    void workflowPolicyRejectsInvalidTerminalTransitionThroughExistingExceptionPath() {
        AppealWorkflowDecisionPolicy policy = new AppealWorkflowDecisionPolicy();

        assertThatThrownBy(() -> policy.resolveProcessStatus(AppealProcessState.UNDER_REVIEW, "Approved"))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("Invalid appeal status transition");
    }

    @Test
    void visibilityPolicyFiltersDeletedAndOffenseMismatchedRecords() {
        AppealVisibilityPolicy policy = new AppealVisibilityPolicy();
        AppealVisibilityPolicy.AppealVisibilityContext context =
                AppealVisibilityPolicy.AppealVisibilityContext.forOffense(20L);
        AppealRecord visible = appealRecord(1L, 20L, null);
        AppealRecord deleted = appealRecord(2L, 20L, LocalDateTime.parse("2026-05-08T12:00:00"));
        AppealRecord otherOffense = appealRecord(3L, 21L, null);

        assertThat(policy.isVisible(visible, context)).isTrue();
        assertThat(policy.isVisible(deleted, context)).isFalse();
        assertThat(policy.isVisible(otherOffense, context)).isFalse();
        assertThat(policy.filterVisible(List.of(visible, deleted, otherOffense), context))
                .containsExactly(visible);
    }

    @Test
    void queryPolicyUsesSameVisibilityForSearchAndFallbackResults() {
        AppealQueryPolicy policy = new AppealQueryPolicy();
        AppealVisibilityPolicy.AppealVisibilityContext context = policy.offenseVisibility(20L);
        AppealRecord visible = appealRecord(1L, 20L, null);
        AppealRecord deleted = appealRecord(2L, 20L, LocalDateTime.parse("2026-05-08T12:00:00"));
        AppealRecord otherOffense = appealRecord(3L, 21L, null);

        assertThat(policy.visibleRecord(Optional.of(visible), context)).contains(visible);
        assertThat(policy.visibleRecord(Optional.of(deleted), context)).isEmpty();
        assertThat(policy.visibleRecords(List.of(deleted, visible, otherOffense), context))
                .containsExactly(visible);
    }

    @Test
    void queryPolicyCapturesFallbackAndBackfillRules() {
        AppealQueryPolicy policy = new AppealQueryPolicy();
        AppealRecord record = new AppealRecord();

        assertThat(policy.shouldReturnEmptyForTextFilter(null)).isTrue();
        assertThat(policy.shouldReturnEmptyForTextFilter("   ")).isTrue();
        assertThat(policy.shouldReturnEmptyForTextFilter("AP-1")).isFalse();
        assertThat(policy.hasIndexedRecord(Optional.of(record))).isTrue();
        assertThat(policy.hasIndexedRecord(Optional.empty())).isFalse();
        assertThat(policy.shouldUseDbFallback(List.of())).isTrue();
        assertThat(policy.shouldUseDbFallback(null)).isTrue();
        assertThat(policy.shouldUseDbFallback(List.of(record))).isFalse();
        assertThat(policy.shouldBackfill((AppealRecord) null)).isFalse();
        assertThat(policy.shouldBackfill(record)).isTrue();
        assertThat(policy.shouldBackfill(List.of())).isFalse();
        assertThat(policy.shouldBackfill(List.of(record))).isTrue();
    }

    @Test
    void queryPolicyRejectsIncompleteTimeRanges() {
        AppealQueryPolicy policy = new AppealQueryPolicy();
        LocalDateTime start = LocalDateTime.parse("2026-05-08T10:00:00");
        LocalDateTime end = LocalDateTime.parse("2026-05-08T11:00:00");

        assertThat(policy.shouldReturnEmptyForTimeRange(null, end)).isTrue();
        assertThat(policy.shouldReturnEmptyForTimeRange(start, null)).isTrue();
        assertThat(policy.shouldReturnEmptyForTimeRange(start, end)).isFalse();
    }

    private static SysRequestHistory history(String businessStatus, String requestParams) {
        SysRequestHistory history = new SysRequestHistory();
        history.setBusinessStatus(businessStatus);
        history.setRequestParams(requestParams);
        return history;
    }

    private static AppealRecord appealRecord(Long appealId, Long offenseId, LocalDateTime deletedAt) {
        AppealRecord record = new AppealRecord();
        record.setAppealId(appealId);
        record.setOffenseId(offenseId);
        record.setDeletedAt(deletedAt);
        return record;
    }
}
