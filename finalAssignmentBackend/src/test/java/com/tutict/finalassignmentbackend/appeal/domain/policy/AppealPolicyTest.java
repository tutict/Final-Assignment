package com.tutict.finalassignmentbackend.appeal.domain.policy;

import com.tutict.finalassignmentbackend.config.statemachine.states.AppealProcessState;
import com.tutict.finalassignmentbackend.entity.AppealRecord;
import com.tutict.finalassignmentbackend.entity.SysRequestHistory;
import org.junit.jupiter.api.Test;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;

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
}
