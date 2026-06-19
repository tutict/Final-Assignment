package com.tutict.finalassignmentbackend.service.appeal;

import com.tutict.finalassignmentbackend.appeal.application.workflow.AppealWorkflowOrchestrator;
import com.tutict.finalassignmentbackend.appeal.query.AppealRecordQueryService;
import com.tutict.finalassignmentbackend.config.statemachine.states.AppealProcessState;
import com.tutict.finalassignmentbackend.config.websocket.WsAction;
import com.tutict.finalassignmentbackend.entity.appeal.AppealRecord;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
public class AppealRecordService {

    private static final String CACHE = "appealRecordCache";

    private final AppealWorkflowOrchestrator workflowOrchestrator;
    private final AppealRecordQueryService queryService;

    public AppealRecordService(
            AppealWorkflowOrchestrator workflowOrchestrator,
            AppealRecordQueryService queryService
    ) {
        this.workflowOrchestrator = workflowOrchestrator;
        this.queryService = queryService;
    }

    @Transactional
    @WsAction(service = "AppealRecordService", action = "checkAndInsertIdempotency", roles = {"SUPER_ADMIN", "ADMIN", "APPEAL_REVIEWER"})
    public void checkAndInsertIdempotency(String idempotencyKey, AppealRecord appealRecord, String action) {
        workflowOrchestrator.checkAndInsertIdempotency(idempotencyKey, appealRecord, action);
    }

    @Transactional
    public AppealRecord createAppeal(AppealRecord appealRecord) {
        return workflowOrchestrator.createAppeal(appealRecord);
    }

    @Transactional
    public AppealRecord updateAppeal(AppealRecord appealRecord) {
        return workflowOrchestrator.updateAppeal(appealRecord);
    }

    /**
     * 供工作流调用的状态更新方法，只改 processStatus 字段
     */
    public AppealRecord updateProcessStatus(Long appealId, AppealProcessState newState) {
        return workflowOrchestrator.updateProcessStatus(appealId, newState);
    }

    @Transactional
    public AppealRecord applyKafkaEvent(AppealRecord appealRecord, String action) {
        return workflowOrchestrator.applyKafkaEvent(appealRecord, action);
    }

    @Transactional
    public void deleteAppeal(Long appealId) {
        workflowOrchestrator.deleteAppeal(appealId);
    }

    @Cacheable(cacheNames = CACHE, key = "#appealId", unless = "@appealCachePolicy.shouldSkipCache(#result)")
    public AppealRecord getAppealById(Long appealId) {
        return queryService.getAppealById(appealId);
    }

    @Cacheable(cacheNames = CACHE, key = "'offense:' + #offenseId + ':' + #page + ':' + #size", unless = "@appealCachePolicy.shouldSkipCache(#result)")
    public List<AppealRecord> findByOffenseId(Long offenseId, int page, int size) {
        return queryService.findByOffenseId(offenseId, page, size);
    }

    @Cacheable(cacheNames = CACHE, key = "'driver:' + #driverId + ':' + #page + ':' + #size", unless = "@appealCachePolicy.shouldSkipCache(#result)")
    public List<AppealRecord> findByDriverId(Long driverId, int page, int size) {
        return queryService.findByDriverId(driverId, page, size);
    }

    @Cacheable(cacheNames = CACHE, key = "'appealNumberPrefix:' + #appealNumber + ':' + #page + ':' + #size", unless = "@appealCachePolicy.shouldSkipCache(#result)")
    public List<AppealRecord> searchByAppealNumberPrefix(String appealNumber, int page, int size) {
        return queryService.searchByAppealNumberPrefix(appealNumber, page, size);
    }

    @Cacheable(cacheNames = CACHE, key = "'appealNumberFuzzy:' + #appealNumber + ':' + #page + ':' + #size", unless = "@appealCachePolicy.shouldSkipCache(#result)")
    public List<AppealRecord> searchByAppealNumberFuzzy(String appealNumber, int page, int size) {
        return queryService.searchByAppealNumberFuzzy(appealNumber, page, size);
    }

    @Cacheable(cacheNames = CACHE, key = "'appellantNamePrefix:' + #appellantName + ':' + #page + ':' + #size", unless = "@appealCachePolicy.shouldSkipCache(#result)")
    public List<AppealRecord> searchByAppellantNamePrefix(String appellantName, int page, int size) {
        return queryService.searchByAppellantNamePrefix(appellantName, page, size);
    }

    @Cacheable(cacheNames = CACHE, key = "'appellantNameFuzzy:' + #appellantName + ':' + #page + ':' + #size", unless = "@appealCachePolicy.shouldSkipCache(#result)")
    public List<AppealRecord> searchByAppellantNameFuzzy(String appellantName, int page, int size) {
        return queryService.searchByAppellantNameFuzzy(appellantName, page, size);
    }

    @Cacheable(cacheNames = CACHE, key = "'appellantIdCard:' + #appellantIdCard + ':' + #page + ':' + #size", unless = "@appealCachePolicy.shouldSkipCache(#result)")
    public List<AppealRecord> searchByAppellantIdCard(String appellantIdCard, int page, int size) {
        return queryService.searchByAppellantIdCard(appellantIdCard, page, size);
    }

    @Cacheable(cacheNames = CACHE, key = "'acceptanceStatus:' + #acceptanceStatus + ':' + #page + ':' + #size", unless = "@appealCachePolicy.shouldSkipCache(#result)")
    public List<AppealRecord> searchByAcceptanceStatus(String acceptanceStatus, int page, int size) {
        return queryService.searchByAcceptanceStatus(acceptanceStatus, page, size);
    }

    @Cacheable(cacheNames = CACHE, key = "'processStatus:' + #processStatus + ':' + #page + ':' + #size", unless = "@appealCachePolicy.shouldSkipCache(#result)")
    public List<AppealRecord> searchByProcessStatus(String processStatus, int page, int size) {
        return queryService.searchByProcessStatus(processStatus, page, size);
    }

    @Cacheable(cacheNames = CACHE, key = "'appealTimeRange:' + #startTime + ':' + #endTime + ':' + #page + ':' + #size", unless = "@appealCachePolicy.shouldSkipCache(#result)")
    public List<AppealRecord> searchByAppealTimeRange(String startTime, String endTime, int page, int size) {
        return queryService.searchByAppealTimeRange(startTime, endTime, page, size);
    }

    @Cacheable(cacheNames = CACHE, key = "'acceptanceHandler:' + #acceptanceHandler + ':' + #page + ':' + #size", unless = "@appealCachePolicy.shouldSkipCache(#result)")
    public List<AppealRecord> searchByAcceptanceHandler(String acceptanceHandler, int page, int size) {
        return queryService.searchByAcceptanceHandler(acceptanceHandler, page, size);
    }

    @Cacheable(cacheNames = CACHE, key = "'createdBy:' + #createdBy + ':' + #page + ':' + #size", unless = "@appealCachePolicy.shouldSkipCache(#result)")
    public List<AppealRecord> findByCreatedBy(String createdBy, int page, int size) {
        return queryService.findByCreatedBy(createdBy, page, size);
    }

    public boolean shouldSkipProcessing(String idempotencyKey) {
        return workflowOrchestrator.shouldSkipProcessing(idempotencyKey);
    }

    public void markHistorySuccess(String idempotencyKey, Long appealId) {
        workflowOrchestrator.markHistorySuccess(idempotencyKey, appealId);
    }

    public void markHistoryFailure(String idempotencyKey, String reason) {
        workflowOrchestrator.markHistoryFailure(idempotencyKey, reason);
    }

}
