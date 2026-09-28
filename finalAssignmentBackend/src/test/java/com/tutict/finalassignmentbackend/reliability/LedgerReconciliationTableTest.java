package com.tutict.finalassignmentbackend.reliability;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.Test;

class LedgerReconciliationTableTest {

    @Test
    void unknownBusinessTypeDoesNotNameATable() {
        assertThat(LedgerReconciliationService.tableFor("NOTE")).isNull();
        assertThat(LedgerReconciliationService.tableFor(null)).isNull();
        assertThat(LedgerReconciliationService.idColumnFor(null)).isNull();
    }

    @Test
    void appealReviewIsNotMatchedAsAppeal() {
        assertThat(LedgerReconciliationService.tableFor("APPEAL_REVIEW")).isEqualTo("appeal_review");
        assertThat(LedgerReconciliationService.idColumnFor("appeal_review")).isEqualTo("review_id");
    }
}
