package com.tutict.finalassignmentcloud.traffic.reliability;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;

import org.junit.jupiter.api.Test;

class LedgerReconciliationTableTest {

    @Test
    void unknownBusinessTypeDoesNotNameAColumn() {
        assertNull(LedgerReconciliationService.tableFor("NOTE"));
        assertNull(LedgerReconciliationService.tableFor(null));
        assertNull(LedgerReconciliationService.idColumnFor("NOTE"));
        assertNull(LedgerReconciliationService.idColumnFor(null));
    }

    @Test
    void appealReviewIsNotMatchedAsAppeal() {
        assertEquals("appeal_review", LedgerReconciliationService.tableFor("APPEAL_REVIEW"));
        assertEquals("review_id", LedgerReconciliationService.idColumnFor("APPEAL_REVIEW"));
    }
}
