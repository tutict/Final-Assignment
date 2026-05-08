package com.tutict.finalassignmentbackend.appeal.application.workflow;

import com.tutict.finalassignmentbackend.appeal.application.AppealRecordApplicationService;
import com.tutict.finalassignmentbackend.config.statemachine.states.AppealProcessState;
import com.tutict.finalassignmentbackend.entity.AppealRecord;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class AppealWorkflowOrchestrator {

    private final AppealRecordApplicationService applicationService;

    public AppealWorkflowOrchestrator(AppealRecordApplicationService applicationService) {
        this.applicationService = applicationService;
    }

    @Transactional
    public void checkAndInsertIdempotency(String idempotencyKey, AppealRecord appealRecord, String action) {
        applicationService.checkAndInsertIdempotency(idempotencyKey, appealRecord, action);
    }

    @Transactional
    public AppealRecord createAppeal(AppealRecord appealRecord) {
        return applicationService.createAppeal(appealRecord);
    }

    @Transactional
    public AppealRecord updateAppeal(AppealRecord appealRecord) {
        return applicationService.updateAppeal(appealRecord);
    }

    @Transactional
    public AppealRecord updateProcessStatus(Long appealId, AppealProcessState newState) {
        return applicationService.updateProcessStatus(appealId, newState);
    }

    @Transactional
    public void deleteAppeal(Long appealId) {
        applicationService.deleteAppeal(appealId);
    }

    public boolean shouldSkipProcessing(String idempotencyKey) {
        return applicationService.shouldSkipProcessing(idempotencyKey);
    }

    public void markHistorySuccess(String idempotencyKey, Long appealId) {
        applicationService.markHistorySuccess(idempotencyKey, appealId);
    }

    public void markHistoryFailure(String idempotencyKey, String reason) {
        applicationService.markHistoryFailure(idempotencyKey, reason);
    }
}
