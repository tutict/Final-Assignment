package com.tutict.finalassignmentbackend.reliability;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

import java.sql.ResultSet;
import org.junit.jupiter.api.Test;

class LedgerReconciliationRowTest {

    @Test
    void unsignedBusinessIdIsReadAsLong() throws Exception {
        ResultSet rs = mock(ResultSet.class);
        when(rs.getLong("business_id")).thenReturn(13L);
        when(rs.wasNull()).thenReturn(false);

        assertThat(LedgerReconciliationService.readLongOrNull(rs, "business_id")).isEqualTo(13L);
    }

    @Test
    void nullBusinessIdStaysNull() throws Exception {
        ResultSet rs = mock(ResultSet.class);
        when(rs.getLong("business_id")).thenReturn(0L);
        when(rs.wasNull()).thenReturn(true);

        assertThat(LedgerReconciliationService.readLongOrNull(rs, "business_id")).isNull();
    }
}
