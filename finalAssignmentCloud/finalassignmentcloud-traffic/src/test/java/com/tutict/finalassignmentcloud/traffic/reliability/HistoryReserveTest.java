package com.tutict.finalassignmentcloud.traffic.reliability;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.tutict.finalassignmentcloud.entity.SysRequestHistory;
import com.tutict.finalassignmentcloud.traffic.mapper.SysRequestHistoryMapper;
import java.time.LocalDateTime;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;

class HistoryReserveTest {

    @Test
    void firstReserveStaysProcessing() {
        SysRequestHistoryMapper mapper = mock(SysRequestHistoryMapper.class);
        when(mapper.selectByIdempotencyKey("fine-1")).thenReturn(null);

        HistoryReserve.reserve(mapper, "fine-1", "FINE_CREATE", "sha256:a");

        ArgumentCaptor<SysRequestHistory> captor = ArgumentCaptor.forClass(SysRequestHistory.class);
        verify(mapper).insert(captor.capture());
        assertEquals("PROCESSING", captor.getValue().getBusinessStatus());
        assertEquals("sha256:a", captor.getValue().getRequestParams());
        assertEquals("FINE_CREATE", captor.getValue().getBusinessType());
    }

    @Test
    void sameFingerprintReplaysWithoutWritingSuccess() {
        SysRequestHistoryMapper mapper = mock(SysRequestHistoryMapper.class);
        SysRequestHistory existing = new SysRequestHistory();
        existing.setBusinessStatus("SUCCESS");
        existing.setRequestParams("sha256:a");
        existing.setUpdatedAt(LocalDateTime.now());
        when(mapper.selectByIdempotencyKey("fine-1")).thenReturn(existing);

        assertThrows(IdempotencyReplayException.class,
                () -> HistoryReserve.reserve(mapper, "fine-1", "FINE_CREATE", "sha256:a"));
    }

    @Test
    void differentFingerprintConflicts() {
        SysRequestHistoryMapper mapper = mock(SysRequestHistoryMapper.class);
        SysRequestHistory existing = new SysRequestHistory();
        existing.setBusinessStatus("SUCCESS");
        existing.setRequestParams("sha256:a");
        existing.setUpdatedAt(LocalDateTime.now());
        when(mapper.selectByIdempotencyKey("fine-1")).thenReturn(existing);

        assertThrows(IdempotencyConflictException.class,
                () -> HistoryReserve.reserve(mapper, "fine-1", "FINE_CREATE", "sha256:b"));
    }
}
