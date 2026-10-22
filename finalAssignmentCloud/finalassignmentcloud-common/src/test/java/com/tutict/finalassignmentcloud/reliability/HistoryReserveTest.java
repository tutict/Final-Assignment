package com.tutict.finalassignmentcloud.reliability;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.isNull;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.baomidou.mybatisplus.core.conditions.Wrapper;
import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.tutict.finalassignmentcloud.entity.SysRequestHistory;
import java.time.LocalDateTime;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.springframework.dao.DuplicateKeyException;

class HistoryReserveTest {

    private static final String FINGERPRINT_A = LedgerFingerprint.PREFIX + "a".repeat(64);
    private static final String FINGERPRINT_B = LedgerFingerprint.PREFIX + "b".repeat(64);

    @SuppressWarnings("unchecked")
    private BaseMapper<SysRequestHistory> mapperReturning(SysRequestHistory existing) {
        BaseMapper<SysRequestHistory> mapper = mock(BaseMapper.class);
        when(mapper.selectOne(any(Wrapper.class))).thenReturn(existing);
        return mapper;
    }

    @Test
    void firstReserveStaysProcessing() {
        BaseMapper<SysRequestHistory> mapper = mapperReturning(null);

        HistoryReserve.reserve(mapper, "fine-1", "FINE_CREATE", FINGERPRINT_A);

        ArgumentCaptor<SysRequestHistory> captor = ArgumentCaptor.forClass(SysRequestHistory.class);
        verify(mapper).insert(captor.capture());
        assertEquals("PROCESSING", captor.getValue().getBusinessStatus());
        assertEquals(FINGERPRINT_A, captor.getValue().getRequestParams());
        assertEquals("FINE_CREATE", captor.getValue().getBusinessType());
    }

    @Test
    void sameFingerprintReplays() {
        SysRequestHistory existing = new SysRequestHistory();
        existing.setBusinessStatus("SUCCESS");
        existing.setRequestParams(FINGERPRINT_A);
        existing.setUpdatedAt(LocalDateTime.now());
        BaseMapper<SysRequestHistory> mapper = mapperReturning(existing);

        assertThrows(IdempotencyReplayException.class,
                () -> HistoryReserve.reserve(mapper, "fine-1", "FINE_CREATE", FINGERPRINT_A));
    }

    @Test
    void differentFingerprintConflicts() {
        SysRequestHistory existing = new SysRequestHistory();
        existing.setBusinessStatus("SUCCESS");
        existing.setRequestParams(FINGERPRINT_A);
        existing.setUpdatedAt(LocalDateTime.now());
        BaseMapper<SysRequestHistory> mapper = mapperReturning(existing);

        assertThrows(IdempotencyConflictException.class,
                () -> HistoryReserve.reserve(mapper, "fine-1", "FINE_CREATE", FINGERPRINT_B));
    }

    @Test
    void concurrentInsertFallsBackToReplayDecision() {
        BaseMapper<SysRequestHistory> mapper = mock(BaseMapper.class);
        SysRequestHistory concurrent = new SysRequestHistory();
        concurrent.setBusinessStatus("SUCCESS");
        concurrent.setRequestParams(FINGERPRINT_A);
        concurrent.setUpdatedAt(LocalDateTime.now());
        when(mapper.selectOne(any(Wrapper.class))).thenReturn(null, concurrent);
        when(mapper.insert(any(SysRequestHistory.class))).thenThrow(new DuplicateKeyException("uk_idempotency_key"));

        assertThrows(IdempotencyReplayException.class,
                () -> HistoryReserve.reserve(mapper, "fine-1", "FINE_CREATE", FINGERPRINT_A));
    }

    @Test
    void concurrentInsertRereadsWithLockingRead() {
        BaseMapper<SysRequestHistory> mapper = mock(BaseMapper.class);
        SysRequestHistory concurrent = new SysRequestHistory();
        concurrent.setBusinessStatus("SUCCESS");
        concurrent.setRequestParams(FINGERPRINT_A);
        concurrent.setUpdatedAt(LocalDateTime.now());
        when(mapper.selectOne(any(Wrapper.class))).thenReturn(null, concurrent);
        when(mapper.insert(any(SysRequestHistory.class))).thenThrow(new DuplicateKeyException("uk_idempotency_key"));

        assertThrows(IdempotencyReplayException.class,
                () -> HistoryReserve.reserve(mapper, "fine-1", "FINE_CREATE", FINGERPRINT_A));

        @SuppressWarnings("unchecked")
        ArgumentCaptor<Wrapper<SysRequestHistory>> captor = ArgumentCaptor.forClass(Wrapper.class);
        verify(mapper, times(2)).selectOne(captor.capture());
        // 冲突回读必须用加锁读：可重复读下的一致读看不到并发事务提交的行。
        assertFalse(captor.getAllValues().get(0).getCustomSqlSegment().contains("FOR UPDATE"));
        assertTrue(captor.getAllValues().get(1).getCustomSqlSegment().contains("FOR UPDATE"));
    }

    @Test
    void retryUsesCompareAndSetAndFailsWhenAnotherRequestWon() {
        SysRequestHistory existing = new SysRequestHistory();
        existing.setBusinessStatus("FAILED");
        existing.setRequestParams(FINGERPRINT_A);
        existing.setUpdatedAt(LocalDateTime.now());
        BaseMapper<SysRequestHistory> mapper = mapperReturning(existing);
        when(mapper.update(isNull(), any(Wrapper.class))).thenReturn(0);

        assertThrows(IdempotencyInProgressException.class,
                () -> HistoryReserve.reserve(mapper, "fine-1", "FINE_CREATE", FINGERPRINT_A));
    }

    @Test
    void retryTakesOverWhenCompareAndSetSucceeds() {
        SysRequestHistory existing = new SysRequestHistory();
        existing.setBusinessStatus("FAILED");
        existing.setRequestParams(FINGERPRINT_A);
        existing.setUpdatedAt(LocalDateTime.now());
        BaseMapper<SysRequestHistory> mapper = mapperReturning(existing);
        when(mapper.update(isNull(), any(Wrapper.class))).thenReturn(1);

        HistoryReserve.reserve(mapper, "fine-1", "FINE_CREATE", FINGERPRINT_A);

        verify(mapper).update(isNull(), any(Wrapper.class));
    }

    @Test
    void markSuccessOnlyMovesProcessingRows() {
        BaseMapper<SysRequestHistory> mapper = mock(BaseMapper.class);
        when(mapper.update(isNull(), any(Wrapper.class))).thenReturn(1);

        assertTrue(HistoryReserve.markSuccess(mapper, "fine-1", 42L));
        verify(mapper, never()).update(any(SysRequestHistory.class), any(Wrapper.class));
    }

    @Test
    void markFailureOnlyMovesProcessingRows() {
        BaseMapper<SysRequestHistory> mapper = mock(BaseMapper.class);
        when(mapper.update(isNull(), any(Wrapper.class))).thenReturn(1);

        assertTrue(HistoryReserve.markFailure(mapper, "fine-1"));
    }

    @Test
    void overlongKeysAreFoldedIntoADigest() {
        String key = "k".repeat(200);
        String normalized = HistoryReserve.normalizeKey(key);

        assertEquals(64, normalized.length());
        assertEquals(normalized, HistoryReserve.normalizeKey(key));
    }

    @Test
    void sha256MatchesColumnWidth() {
        assertEquals(64, LedgerFingerprint.sha256("payload").length());
    }

    @Test
    void legacyReservationMarkerIsTreatedAsAlreadyProcessed() {
        SysRequestHistory existing = new SysRequestHistory();
        existing.setBusinessStatus("SUCCESS");
        existing.setRequestParams("PENDING");
        existing.setUpdatedAt(LocalDateTime.now());
        BaseMapper<SysRequestHistory> mapper = mapperReturning(existing);

        assertThrows(IdempotencyReplayException.class,
                () -> HistoryReserve.reserve(mapper, "fine-1", "FINE_CREATE", FINGERPRINT_B));
    }

    @Test
    void freshReservationIsReportedAsInProgress() {
        SysRequestHistory existing = new SysRequestHistory();
        existing.setBusinessStatus("PROCESSING");
        existing.setRequestParams(FINGERPRINT_A);
        existing.setUpdatedAt(LocalDateTime.now());
        BaseMapper<SysRequestHistory> mapper = mapperReturning(existing);

        assertThrows(IdempotencyInProgressException.class,
                () -> HistoryReserve.reserve(mapper, "fine-1", "FINE_CREATE", FINGERPRINT_A));
    }
}
