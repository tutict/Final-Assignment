package com.tutict.finalassignmentbackend.offense.governance;

import com.tutict.finalassignmentbackend.entity.OffenseRecord;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.time.LocalDateTime;

import static org.assertj.core.api.Assertions.assertThat;

class OffenseUpdateMergeCoordinatorTest {

    private final OffenseUpdateMergeCoordinator coordinator = new OffenseUpdateMergeCoordinator();

    @Test
    void workflowCannotOverwriteBusinessFields() {
        OffenseRecord current = baseRecord();
        current.setOffenseDescription("current business description");
        current.setFineAmount(new BigDecimal("100.00"));
        current.setProcessStatus("Unprocessed");

        OffenseRecord incoming = new OffenseRecord();
        incoming.setOffenseId(999L);
        incoming.setOffenseDescription("stale workflow business overwrite");
        incoming.setFineAmount(new BigDecimal("1.00"));
        incoming.setProcessStatus("Processing");

        OffenseRecord merged = coordinator.merge(current, incoming, SemanticEventType.WORKFLOW);

        assertThat(merged.getOffenseId()).isEqualTo(10L);
        assertThat(merged.getOffenseDescription()).isEqualTo("current business description");
        assertThat(merged.getFineAmount()).isEqualByComparingTo("100.00");
        assertThat(merged.getProcessStatus()).isEqualTo("Processing");
    }

    @Test
    void immutableIdsArePreservedForFullUpdate() {
        OffenseRecord current = baseRecord();
        current.setOffenseId(10L);
        current.setOffenseNumber("OF-001");

        OffenseRecord incoming = new OffenseRecord();
        incoming.setOffenseId(99L);
        incoming.setOffenseNumber("OF-999");
        incoming.setOffenseCode("NEW-CODE");

        OffenseRecord merged = coordinator.merge(current, incoming, SemanticEventType.FULL_UPDATE);

        assertThat(merged.getOffenseId()).isEqualTo(10L);
        assertThat(merged.getOffenseNumber()).isEqualTo("OF-001");
        assertThat(merged.getOffenseCode()).isEqualTo("NEW-CODE");
    }

    @Test
    void noOpReturnsCurrentEntityUnchanged() {
        OffenseRecord current = baseRecord();
        OffenseRecord incoming = new OffenseRecord();
        incoming.setOffenseCode("SHOULD_NOT_APPLY");

        OffenseRecord merged = coordinator.merge(current, incoming, SemanticEventType.NO_OP);

        assertThat(merged).isSameAs(current);
        assertThat(merged.getOffenseCode()).isEqualTo("OLD-CODE");
    }

    @Test
    void fullUpdatePreservesUnspecifiedImmutableFields() {
        OffenseRecord current = baseRecord();
        current.setOffenseId(10L);
        current.setOffenseNumber("OF-001");
        current.setOffenseLocation("Old Location");

        OffenseRecord incoming = new OffenseRecord();
        incoming.setOffenseLocation("New Location");

        OffenseRecord merged = coordinator.merge(current, incoming, SemanticEventType.FULL_UPDATE);

        assertThat(merged.getOffenseId()).isEqualTo(10L);
        assertThat(merged.getOffenseNumber()).isEqualTo("OF-001");
        assertThat(merged.getOffenseLocation()).isEqualTo("New Location");
    }

    @Test
    void staleWorkflowPayloadCannotDowngradeBusinessFields() {
        OffenseRecord current = baseRecord();
        current.setOffenseCode("LATEST-CODE");
        current.setOffenseLocation("Latest Location");
        current.setFineAmount(new BigDecimal("500.00"));
        current.setProcessStatus("Processed");

        OffenseRecord staleWorkflowPayload = new OffenseRecord();
        staleWorkflowPayload.setOffenseCode("OLD-CODE");
        staleWorkflowPayload.setOffenseLocation("Old Location");
        staleWorkflowPayload.setFineAmount(new BigDecimal("50.00"));
        staleWorkflowPayload.setProcessStatus("Appealing");
        staleWorkflowPayload.setUpdatedAt(LocalDateTime.of(2026, 5, 8, 12, 0));

        OffenseRecord merged = coordinator.merge(current, staleWorkflowPayload, SemanticEventType.WORKFLOW);

        assertThat(merged.getOffenseCode()).isEqualTo("LATEST-CODE");
        assertThat(merged.getOffenseLocation()).isEqualTo("Latest Location");
        assertThat(merged.getFineAmount()).isEqualByComparingTo("500.00");
        assertThat(merged.getProcessStatus()).isEqualTo("Appealing");
        assertThat(merged.getUpdatedAt()).isEqualTo(LocalDateTime.of(2026, 5, 8, 12, 0));
    }

    @Test
    void fieldPolicyClassifiesOffenseFieldsExplicitly() {
        OffenseFieldMergePolicy policy = new OffenseFieldMergePolicy();

        assertThat(policy.categoryOf("offenseCode")).isEqualTo(OffenseFieldMergePolicy.FieldCategory.BUSINESS_FIELDS);
        assertThat(policy.categoryOf("processStatus")).isEqualTo(OffenseFieldMergePolicy.FieldCategory.WORKFLOW_FIELDS);
        assertThat(policy.categoryOf("notificationStatus")).isEqualTo(OffenseFieldMergePolicy.FieldCategory.SYSTEM_FIELDS);
        assertThat(policy.categoryOf("offenseId")).isEqualTo(OffenseFieldMergePolicy.FieldCategory.IMMUTABLE_FIELDS);
        assertThat(policy.categoryOf("unknown")).isEqualTo(OffenseFieldMergePolicy.FieldCategory.UNKNOWN);
    }

    private OffenseRecord baseRecord() {
        OffenseRecord record = new OffenseRecord();
        record.setOffenseId(10L);
        record.setOffenseNumber("OF-001");
        record.setOffenseCode("OLD-CODE");
        record.setOffenseTime(LocalDateTime.of(2026, 5, 8, 10, 0));
        record.setOffenseLocation("Old Location");
        record.setOffenseProvince("Old Province");
        record.setOffenseCity("Old City");
        record.setDriverId(20L);
        record.setVehicleId(30L);
        record.setCreatedAt(LocalDateTime.of(2026, 5, 8, 9, 0));
        return record;
    }
}
