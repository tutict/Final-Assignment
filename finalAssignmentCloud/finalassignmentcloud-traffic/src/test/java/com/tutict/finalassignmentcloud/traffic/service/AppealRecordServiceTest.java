package com.tutict.finalassignmentcloud.traffic.service;

import com.tutict.finalassignmentcloud.entity.AppealRecord;
import com.tutict.finalassignmentcloud.traffic.config.statemachine.states.AppealProcessState;
import com.tutict.finalassignmentcloud.traffic.mapper.AppealRecordMapper;
import com.tutict.finalassignmentcloud.traffic.mapper.SysRequestHistoryMapper;
import com.tutict.finalassignmentcloud.traffic.realtime.BusinessEventPublisher;
import com.tutict.finalassignmentcloud.traffic.repository.AppealRecordSearchRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class AppealRecordServiceTest {

    @Mock
    private AppealRecordMapper appealRecordMapper;

    @Mock
    private SysRequestHistoryMapper sysRequestHistoryMapper;

    @Mock
    private AppealRecordSearchRepository appealRecordSearchRepository;

    @Mock
    private BusinessEventPublisher businessEventPublisher;

    @InjectMocks
    private AppealRecordService appealRecordService;

    @Test
    void rejectedWorkflowPersistsTrimmedRejectionReason() {
        AppealRecord existing = appeal(1L, "Under_Review");
        when(appealRecordMapper.selectById(1L)).thenReturn(existing);
        when(appealRecordMapper.updateById(any(AppealRecord.class))).thenReturn(1);

        AppealRecord updated = appealRecordService.updateProcessStatus(
                1L, AppealProcessState.REJECTED, "  证据不足  ");

        assertEquals("Rejected", updated.getProcessStatus());
        assertEquals("证据不足", updated.getRejectionReason());
        verify(appealRecordMapper).updateById(updated);
    }

    @Test
    void nonRejectedWorkflowKeepsExistingRejectionReason() {
        AppealRecord existing = appeal(2L, "Under_Review");
        existing.setRejectionReason("历史原因");
        when(appealRecordMapper.selectById(2L)).thenReturn(existing);
        when(appealRecordMapper.updateById(any(AppealRecord.class))).thenReturn(1);

        AppealRecord updated = appealRecordService.updateProcessStatus(
                2L, AppealProcessState.APPROVED, "不应写入");

        assertEquals("Approved", updated.getProcessStatus());
        assertEquals("历史原因", updated.getRejectionReason());
    }

    @Test
    void blankReasonOnRejectKeepsExistingRejectionReason() {
        AppealRecord existing = appeal(3L, "Under_Review");
        existing.setRejectionReason("历史原因");
        when(appealRecordMapper.selectById(3L)).thenReturn(existing);
        when(appealRecordMapper.updateById(any(AppealRecord.class))).thenReturn(1);

        AppealRecord updated = appealRecordService.updateProcessStatus(
                3L, AppealProcessState.REJECTED, "   ");

        assertEquals("Rejected", updated.getProcessStatus());
        assertEquals("历史原因", updated.getRejectionReason());
    }

    private static AppealRecord appeal(Long appealId, String processStatus) {
        AppealRecord record = new AppealRecord();
        record.setAppealId(appealId);
        record.setProcessStatus(processStatus);
        return record;
    }
}
