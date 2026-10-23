package finalassignmentbackend.service.appeal;

import finalassignmentbackend.config.statemachine.states.AppealProcessState;
import finalassignmentbackend.entity.AppealRecord;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;

class AppealManagementServiceTest {

    @Test
    void rejectedStatusAppliesTrimmedReason() {
        AppealRecord record = new AppealRecord();
        record.setProcessStatus("Under_Review");

        AppealManagementService.applyAppealStatus(record, AppealProcessState.REJECTED, "  证据不足  ");

        assertEquals("Rejected", record.getProcessStatus());
        assertEquals("证据不足", record.getRejectionReason());
    }

    @Test
    void approvedStatusDoesNotWriteReason() {
        AppealRecord record = new AppealRecord();
        record.setProcessStatus("Under_Review");
        record.setRejectionReason("历史原因");

        AppealManagementService.applyAppealStatus(record, AppealProcessState.APPROVED, "不应写入");

        assertEquals("Approved", record.getProcessStatus());
        assertEquals("历史原因", record.getRejectionReason());
    }

    @Test
    void blankReasonOnRejectKeepsExistingReason() {
        AppealRecord record = new AppealRecord();
        record.setProcessStatus("Under_Review");
        record.setRejectionReason("历史原因");

        AppealManagementService.applyAppealStatus(record, AppealProcessState.REJECTED, "   ");

        assertEquals("Rejected", record.getProcessStatus());
        assertEquals("历史原因", record.getRejectionReason());
    }
}
