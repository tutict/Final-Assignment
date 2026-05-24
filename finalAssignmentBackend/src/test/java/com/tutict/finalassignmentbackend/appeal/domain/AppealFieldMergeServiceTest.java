package com.tutict.finalassignmentbackend.appeal.domain;

import com.tutict.finalassignmentbackend.appeal.domain.policy.AppealFieldMutationPolicy;
import com.tutict.finalassignmentbackend.config.statemachine.states.AppealProcessState;
import com.tutict.finalassignmentbackend.entity.appeal.AppealRecord;
import org.junit.jupiter.api.Test;

import java.time.LocalDateTime;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class AppealFieldMergeServiceTest {

    private final AppealFieldMutationPolicy policy = new AppealFieldMutationPolicy();
    private final AppealFieldMergeService mergeService = new AppealFieldMergeService(policy);

    @Test
    void policyDefinesFieldMutationCategories() {
        assertThat(policy.immutableFields()).contains("appealId", "offenseId", "appealNumber", "appealTime");
        assertThat(policy.mutableFields()).contains("appellantName", "appealReason", "evidenceUrls", "remarks");
        assertThat(policy.systemManagedFields()).contains("processStatus", "createdAt", "updatedAt", "deletedAt");
        assertThat(policy.terminalProtectedFields()).contains("appellantName", "appealReason", "evidenceUrls");
    }

    @Test
    void mergePreservesImmutableFields() {
        AppealRecord existing = existing();
        AppealRecord incoming = incoming();
        incoming.setOffenseId(99L);
        incoming.setAppealNumber("AP-99");
        incoming.setAppealTime(LocalDateTime.parse("2026-05-09T10:00:00"));

        AppealRecord merged = mergeService.merge(existing, incoming);

        assertThat(merged.getAppealId()).isEqualTo(existing.getAppealId());
        assertThat(merged.getOffenseId()).isEqualTo(existing.getOffenseId());
        assertThat(merged.getAppealNumber()).isEqualTo(existing.getAppealNumber());
        assertThat(merged.getAppealTime()).isEqualTo(existing.getAppealTime());
    }

    @Test
    void mergeAppliesMutableFieldsAndPreservesExistingOnNull() {
        AppealRecord existing = existing();
        AppealRecord incoming = incoming();
        incoming.setAppellantName("New Name");
        incoming.setAppealReason(null);
        incoming.setRemarks("New remarks");

        AppealRecord merged = mergeService.merge(existing, incoming);

        assertThat(merged.getAppellantName()).isEqualTo("New Name");
        assertThat(merged.getAppealReason()).isEqualTo(existing.getAppealReason());
        assertThat(merged.getRemarks()).isEqualTo("New remarks");
    }

    @Test
    void mergePreservesSystemManagedFields() {
        AppealRecord existing = existing();
        AppealRecord incoming = incoming();
        incoming.setProcessStatus(AppealProcessState.APPROVED.getCode());
        incoming.setProcessHandler("incoming-handler");
        incoming.setCreatedAt(LocalDateTime.parse("2026-05-01T10:00:00"));
        incoming.setUpdatedBy("incoming-updater");
        incoming.setDeletedAt(LocalDateTime.parse("2026-05-09T10:00:00"));

        AppealRecord merged = mergeService.merge(existing, incoming);

        assertThat(merged.getProcessStatus()).isEqualTo(existing.getProcessStatus());
        assertThat(merged.getProcessHandler()).isEqualTo(existing.getProcessHandler());
        assertThat(merged.getCreatedAt()).isEqualTo(existing.getCreatedAt());
        assertThat(merged.getUpdatedBy()).isEqualTo(existing.getUpdatedBy());
        assertThat(merged.getDeletedAt()).isEqualTo(existing.getDeletedAt());
    }

    @Test
    void terminalStateBlocksProtectedFieldMutationButAllowsRemarks() {
        AppealRecord existing = existing();
        existing.setProcessStatus(AppealProcessState.APPROVED.getCode());
        AppealRecord incoming = incoming();
        incoming.setAppellantName("Illegal Name");

        assertThatThrownBy(() -> mergeService.merge(existing, incoming))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("Cannot update terminal appeal field: appellantName");

        incoming.setAppellantName(existing.getAppellantName());
        incoming.setRemarks("terminal note");
        AppealRecord merged = mergeService.merge(existing, incoming);
        assertThat(merged.getRemarks()).isEqualTo("terminal note");
    }

    @Test
    void mergeOutputIsDeterministicAndNoOpUpdatesKeepExistingValues() {
        AppealRecord existing = existing();
        AppealRecord incoming = new AppealRecord();
        incoming.setAppealId(existing.getAppealId());
        incoming.setOffenseId(99L);
        incoming.setAppealNumber("AP-99");

        AppealRecord first = mergeService.merge(existing, incoming);
        AppealRecord second = mergeService.merge(existing, incoming);

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

    private static AppealRecord incoming() {
        AppealRecord record = new AppealRecord();
        record.setAppealId(10L);
        return record;
    }
}
