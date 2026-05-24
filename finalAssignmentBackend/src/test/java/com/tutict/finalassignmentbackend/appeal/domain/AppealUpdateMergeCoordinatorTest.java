package com.tutict.finalassignmentbackend.appeal.domain;

import com.tutict.finalassignmentbackend.appeal.domain.policy.AppealCallerMetadata;
import com.tutict.finalassignmentbackend.appeal.domain.policy.AppealUpdateIntentPolicy;
import com.tutict.finalassignmentbackend.appeal.domain.policy.AppealUpdateIntentPolicy.UpdateIntent;
import com.tutict.finalassignmentbackend.config.statemachine.states.AppealProcessState;
import com.tutict.finalassignmentbackend.entity.appeal.AppealRecord;
import org.junit.jupiter.api.Test;

import java.time.LocalDateTime;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class AppealUpdateMergeCoordinatorTest {

    private final AppealUpdateIntentPolicy intentPolicy = new AppealUpdateIntentPolicy();
    private final AppealUpdateMergeCoordinator coordinator = new AppealUpdateMergeCoordinator();
    private final AppealCallerMetadata controllerCaller = AppealCallerMetadata.controller("test-controller");
    private final AppealCallerMetadata workflowCaller = AppealCallerMetadata.workflow("test-workflow");
    private final AppealCallerMetadata systemCaller = AppealCallerMetadata.system("test-system");

    @Test
    void intentPolicyDefinesAllowedFieldsPerIntent() {
        assertThat(intentPolicy.allowedFields(UpdateIntent.FULL_UPDATE)).contains("appellantName", "appealReason", "remarks");
        assertThat(intentPolicy.allowedFields(UpdateIntent.PARTIAL_UPDATE)).contains("appellantName", "evidenceUrls", "remarks");
        assertThat(intentPolicy.allowedFields(UpdateIntent.WORKFLOW_UPDATE)).containsExactlyInAnyOrder(
                "processStatus",
                "processTime",
                "processResult",
                "processHandler"
        );
        assertThat(intentPolicy.allowedFields(UpdateIntent.SYSTEM_UPDATE)).contains("acceptanceStatus", "updatedAt", "deletedAt");
    }

    @Test
    void workflowOnlyUpdateDoesNotOverwriteBusinessFields() {
        AppealRecord existing = existing();
        AppealRecord incoming = new AppealRecord();
        incoming.setAppealId(existing.getAppealId());
        incoming.setProcessStatus(AppealProcessState.UNDER_REVIEW.getCode());

        AppealRecord merged = coordinator.merge(existing, incoming, UpdateIntent.WORKFLOW_UPDATE, workflowCaller);

        assertThat(merged.getAppellantName()).isEqualTo(existing.getAppellantName());
        assertThat(merged.getAppealReason()).isEqualTo(existing.getAppealReason());
        assertThat(merged.getProcessStatus()).isEqualTo(AppealProcessState.UNDER_REVIEW.getCode());
    }

    @Test
    void workflowIntentRejectsBusinessFieldMutation() {
        AppealRecord existing = existing();
        AppealRecord incoming = new AppealRecord();
        incoming.setAppealId(existing.getAppealId());
        incoming.setProcessStatus(AppealProcessState.UNDER_REVIEW.getCode());
        incoming.setAppellantName("Illegal Name");

        assertThatThrownBy(() -> coordinator.merge(existing, incoming, UpdateIntent.WORKFLOW_UPDATE, workflowCaller))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("WORKFLOW_UPDATE cannot change business fields");
    }

    @Test
    void fullUpdateCallerIsAcceptedForFullUpdateOnly() {
        AppealRecord existing = existing();
        AppealRecord incoming = new AppealRecord();
        incoming.setAppealId(existing.getAppealId());
        incoming.setRemarks("controller update");

        AppealRecord merged = coordinator.merge(existing, incoming, UpdateIntent.FULL_UPDATE, controllerCaller);

        assertThat(merged.getRemarks()).isEqualTo("controller update");
        assertThatThrownBy(() -> coordinator.merge(existing, incoming, UpdateIntent.WORKFLOW_UPDATE, controllerCaller))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("CONTROLLER cannot execute WORKFLOW_UPDATE");
    }

    @Test
    void unknownCallerIsRejectedWithoutFallbackIntent() {
        AppealRecord existing = existing();
        AppealRecord incoming = new AppealRecord();
        incoming.setAppealId(existing.getAppealId());

        assertThatThrownBy(() -> coordinator.merge(
                existing,
                incoming,
                UpdateIntent.FULL_UPDATE,
                AppealCallerMetadata.unknown()
        ))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("Unknown appeal update caller");
        assertThatThrownBy(() -> coordinator.merge(existing, incoming, UpdateIntent.FULL_UPDATE))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("Unknown appeal update caller");
    }

    @Test
    void workflowCallerCannotUseFullUpdateIntent() {
        AppealRecord existing = existing();
        AppealRecord incoming = new AppealRecord();
        incoming.setAppealId(existing.getAppealId());
        incoming.setAppellantName("Illegal workflow overwrite");

        assertThatThrownBy(() -> coordinator.merge(existing, incoming, UpdateIntent.FULL_UPDATE, workflowCaller))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("WORKFLOW cannot execute FULL_UPDATE");
    }

    @Test
    void fullUpdateAllowsBusinessMutationButPreservesImmutableAndSystemFields() {
        AppealRecord existing = existing();
        AppealRecord incoming = new AppealRecord();
        incoming.setAppealId(existing.getAppealId());
        incoming.setOffenseId(99L);
        incoming.setAppealNumber("AP-99");
        incoming.setAppellantName("New Name");
        incoming.setAppealReason("New reason");
        incoming.setProcessStatus(AppealProcessState.APPROVED.getCode());

        AppealRecord merged = coordinator.merge(existing, incoming, UpdateIntent.FULL_UPDATE, controllerCaller);

        assertThat(merged.getOffenseId()).isEqualTo(existing.getOffenseId());
        assertThat(merged.getAppealNumber()).isEqualTo(existing.getAppealNumber());
        assertThat(merged.getAppellantName()).isEqualTo("New Name");
        assertThat(merged.getAppealReason()).isEqualTo("New reason");
        assertThat(merged.getProcessStatus()).isEqualTo(existing.getProcessStatus());
    }

    @Test
    void partialUpdateRequiresExplicitFutureCallerBeforeUse() {
        AppealRecord existing = existing();
        AppealRecord incoming = new AppealRecord();
        incoming.setAppealId(existing.getAppealId());
        incoming.setAppellantName(null);
        incoming.setRemarks("Patch note");
        incoming.setProcessHandler("illegal-handler");

        assertThatThrownBy(() -> coordinator.merge(existing, incoming, UpdateIntent.PARTIAL_UPDATE, controllerCaller))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("CONTROLLER cannot execute PARTIAL_UPDATE");
    }

    @Test
    void terminalStateRestrictsBusinessMutationThroughExistingExceptionPath() {
        AppealRecord existing = existing();
        existing.setProcessStatus(AppealProcessState.APPROVED.getCode());
        AppealRecord incoming = new AppealRecord();
        incoming.setAppealId(existing.getAppealId());
        incoming.setAppealReason("Illegal terminal mutation");

        assertThatThrownBy(() -> coordinator.merge(existing, incoming, UpdateIntent.FULL_UPDATE, controllerCaller))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("Cannot update terminal appeal field: appealReason");
    }

    @Test
    void staleUpdateIsRejectedBeforeMerge() {
        AppealRecord existing = existing();
        AppealRecord incoming = new AppealRecord();
        incoming.setAppealId(existing.getAppealId());
        incoming.setUpdatedAt(existing.getUpdatedAt().minusMinutes(1));
        incoming.setRemarks("stale");

        assertThatThrownBy(() -> coordinator.merge(existing, incoming, UpdateIntent.FULL_UPDATE, controllerCaller))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("Stale appeal update rejected");
    }

    @Test
    void staleWorkflowUpdateIsRejectedBeforeMerge() {
        AppealRecord existing = existing();
        AppealRecord incoming = new AppealRecord();
        incoming.setAppealId(existing.getAppealId());
        incoming.setProcessStatus(AppealProcessState.UNDER_REVIEW.getCode());
        incoming.setUpdatedAt(existing.getUpdatedAt().minusMinutes(1));

        assertThatThrownBy(() -> coordinator.merge(existing, incoming, UpdateIntent.WORKFLOW_UPDATE, workflowCaller))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("Stale appeal update rejected");
    }

    @Test
    void systemUpdateDoesNotApplyBusinessFields() {
        AppealRecord existing = existing();
        AppealRecord incoming = new AppealRecord();
        incoming.setAppealId(existing.getAppealId());
        incoming.setAcceptanceStatus("RECHECKED");
        incoming.setUpdatedBy("system");
        incoming.setAppellantName("Illegal Name");

        assertThatThrownBy(() -> coordinator.merge(existing, incoming, UpdateIntent.SYSTEM_UPDATE, systemCaller))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("SYSTEM_UPDATE cannot change business fields");

        incoming.setAppellantName(null);
        AppealRecord merged = coordinator.merge(existing, incoming, UpdateIntent.SYSTEM_UPDATE, systemCaller);
        assertThat(merged.getAcceptanceStatus()).isEqualTo("RECHECKED");
        assertThat(merged.getUpdatedBy()).isEqualTo("system");
        assertThat(merged.getAppellantName()).isEqualTo(existing.getAppellantName());
    }

    @Test
    void noOpUpdateHandlingIsExplicitAndDeterministic() {
        AppealRecord existing = existing();
        AppealRecord incoming = new AppealRecord();
        incoming.setAppealId(existing.getAppealId());

        AppealRecord first = coordinator.merge(existing, incoming, UpdateIntent.FULL_UPDATE, controllerCaller);
        AppealRecord second = coordinator.merge(existing, incoming, UpdateIntent.FULL_UPDATE, controllerCaller);

        assertThat(coordinator.isNoOp(existing, incoming, UpdateIntent.FULL_UPDATE)).isTrue();
        assertThat(first).isEqualTo(second);
        assertThat(first).isEqualTo(existing);
    }

    private static AppealRecord existing() {
        AppealRecord record = new AppealRecord();
        record.setAppealId(10L);
        record.setOffenseId(20L);
        record.setAppealNumber("AP-10");
        record.setAppellantName("Old Name");
        record.setAppellantIdCard("ID-10");
        record.setAppellantContact("123456");
        record.setAppellantEmail("old@example.com");
        record.setAppellantAddress("Old Address");
        record.setAppealType("TYPE");
        record.setAppealReason("Old reason");
        record.setAppealTime(LocalDateTime.parse("2026-05-08T10:00:00"));
        record.setEvidenceDescription("Old evidence");
        record.setEvidenceUrls("old-url");
        record.setAcceptanceStatus("ACCEPTED");
        record.setAcceptanceTime(LocalDateTime.parse("2026-05-08T11:00:00"));
        record.setAcceptanceHandler("handler");
        record.setRejectionReason("rejection");
        record.setProcessStatus(AppealProcessState.UNPROCESSED.getCode());
        record.setProcessTime(LocalDateTime.parse("2026-05-08T12:00:00"));
        record.setProcessResult("result");
        record.setProcessHandler("process-handler");
        record.setCreatedAt(LocalDateTime.parse("2026-05-08T13:00:00"));
        record.setUpdatedAt(LocalDateTime.parse("2026-05-08T14:00:00"));
        record.setCreatedBy("creator");
        record.setUpdatedBy("updater");
        record.setRemarks("old remarks");
        return record;
    }
}
