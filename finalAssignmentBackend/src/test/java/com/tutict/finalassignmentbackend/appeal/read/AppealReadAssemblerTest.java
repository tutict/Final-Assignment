package com.tutict.finalassignmentbackend.appeal.read;

import com.tutict.finalassignmentbackend.appeal.projection.AppealRecordSearchProjection;
import com.tutict.finalassignmentbackend.entity.appeal.AppealRecord;
import org.junit.jupiter.api.Test;

import java.time.LocalDateTime;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

class AppealReadAssemblerTest {

    private final AppealReadAssembler assembler = new AppealReadAssembler();

    @Test
    void projectionStabilityKeepsSearchAndWorkflowViewsFocused() {
        AppealReadModel model = assembler.fromProjection(projection());

        AppealSearchView searchView = assembler.toSearchView(model);
        AppealWorkflowView workflowView = assembler.toWorkflowView(model);

        assertThat(searchView.sourceKey()).isEqualTo("appeal_record:10");
        assertThat(searchView.appealNumber()).isEqualTo("AP-10");
        assertThat(searchView.appealReason()).isEqualTo("wrong plate");
        assertThat(workflowView.appealId()).isEqualTo(10L);
        assertThat(workflowView.processStatus()).isEqualTo("UNDER_REVIEW");
        assertThat(workflowView.processResult()).isEqualTo("accepted for review");
    }

    @Test
    void readAssemblerIsDeterministicAcrossProjectionAndEntitySources() {
        AppealReadModel fromProjection = assembler.fromProjection(projection());
        AppealReadModel fromEntity = assembler.fromEntity(entity());

        assertThat(fromProjection).isEqualTo(fromEntity);
        assertThat(assembler.normalize(fromProjection)).isEqualTo(fromProjection);
        assertThat(assembler.toSearchView(fromProjection)).isEqualTo(assembler.toSearchView(fromEntity));
    }

    @Test
    void workflowReadSeparationDoesNotExposeWorkflowOperatorsInWorkflowView() {
        AppealWorkflowView workflowView = assembler.toWorkflowView(assembler.fromEntity(entity()));

        assertThat(workflowView.processStatus()).isEqualTo("UNDER_REVIEW");
        assertThat(workflowView.processTime()).isEqualTo(LocalDateTime.parse("2026-05-08T12:00:00"));
        assertThat(workflowView.toString()).doesNotContain("process-operator");
        assertThat(workflowView.toString()).doesNotContain("acceptance-operator");
    }

    @Test
    void retrievalSafeFieldFilteringUsesExplicitWhitelistOnly() {
        AppealReadModel model = assembler.fromEntity(entity());

        Map<String, String> safeFields = assembler.toRetrievalSafeFields(model);

        assertThat(assembler.retrievalSafeFieldNames())
                .containsExactlyInAnyOrder("appealType", "appealReason", "evidenceDescription", "remarks");
        assertThat(safeFields).containsEntry("appealReason", "wrong plate");
        assertThat(safeFields).containsEntry("evidenceDescription", "dashcam");
        assertThat(safeFields).doesNotContainKeys(
                "appealId",
                "offenseId",
                "appellantIdCard",
                "appellantContact",
                "appellantEmail",
                "processStatus",
                "processHandler",
                "createdAt",
                "updatedAt"
        );
    }

    @Test
    void legacyResponseCompatibilityPreservesExistingEntityShape() {
        AppealRecord original = entity();

        AppealRecord legacy = assembler.toLegacyEntity(assembler.fromEntity(original));

        assertThat(legacy).isEqualTo(original);
        assertThat(legacy).isNotSameAs(original);
    }

    private static AppealRecordSearchProjection projection() {
        return new AppealRecordSearchProjection(
                10L,
                20L,
                30L,
                " AP-10 ",
                " Alice ",
                "ID-10",
                "123456",
                "alice@example.com",
                "address",
                "Information_Error",
                " wrong plate ",
                LocalDateTime.parse("2026-05-08T10:00:00"),
                " dashcam ",
                "internal://evidence",
                "ACCEPTED",
                LocalDateTime.parse("2026-05-08T11:00:00"),
                "acceptance-operator",
                "none",
                "UNDER_REVIEW",
                LocalDateTime.parse("2026-05-08T12:00:00"),
                "accepted for review",
                "process-operator",
                LocalDateTime.parse("2026-05-08T13:00:00"),
                LocalDateTime.parse("2026-05-08T14:00:00"),
                "creator",
                "updater",
                null,
                " public note "
        );
    }

    private static AppealRecord entity() {
        AppealRecord entity = new AppealRecord();
        entity.setAppealId(10L);
        entity.setOffenseId(20L);
        entity.setDriverId(30L);
        entity.setAppealNumber("AP-10");
        entity.setAppellantName("Alice");
        entity.setAppellantIdCard("ID-10");
        entity.setAppellantContact("123456");
        entity.setAppellantEmail("alice@example.com");
        entity.setAppellantAddress("address");
        entity.setAppealType("Information_Error");
        entity.setAppealReason("wrong plate");
        entity.setAppealTime(LocalDateTime.parse("2026-05-08T10:00:00"));
        entity.setEvidenceDescription("dashcam");
        entity.setEvidenceUrls("internal://evidence");
        entity.setAcceptanceStatus("ACCEPTED");
        entity.setAcceptanceTime(LocalDateTime.parse("2026-05-08T11:00:00"));
        entity.setAcceptanceHandler("acceptance-operator");
        entity.setRejectionReason("none");
        entity.setProcessStatus("UNDER_REVIEW");
        entity.setProcessTime(LocalDateTime.parse("2026-05-08T12:00:00"));
        entity.setProcessResult("accepted for review");
        entity.setProcessHandler("process-operator");
        entity.setCreatedAt(LocalDateTime.parse("2026-05-08T13:00:00"));
        entity.setUpdatedAt(LocalDateTime.parse("2026-05-08T14:00:00"));
        entity.setCreatedBy("creator");
        entity.setUpdatedBy("updater");
        entity.setRemarks("public note");
        return entity;
    }
}
