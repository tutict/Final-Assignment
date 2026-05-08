package com.tutict.finalassignmentbackend.service;

import com.tutict.finalassignmentbackend.appeal.application.AppealRecordApplicationService;
import com.tutict.finalassignmentbackend.appeal.query.AppealRecordQueryService;
import com.tutict.finalassignmentbackend.config.statemachine.states.AppealProcessState;
import com.tutict.finalassignmentbackend.config.websocket.WsAction;
import com.tutict.finalassignmentbackend.entity.AppealRecord;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
public class AppealRecordService {

    private static final String CACHE = "appealRecordCache";

    private final AppealRecordApplicationService applicationService;
    private final AppealRecordQueryService queryService;

    public AppealRecordService(
            AppealRecordApplicationService applicationService,
            AppealRecordQueryService queryService
    ) {
        this.applicationService = applicationService;
        this.queryService = queryService;
    }

    @Transactional
    @CacheEvict(cacheNames = CACHE, allEntries = true)
    @WsAction(service = "AppealRecordService", action = "checkAndInsertIdempotency")
    public void checkAndInsertIdempotency(String idempotencyKey, AppealRecord appealRecord, String action) {
        applicationService.checkAndInsertIdempotency(idempotencyKey, appealRecord, action);
    }

    @Transactional
    @CacheEvict(cacheNames = CACHE, allEntries = true)
    public AppealRecord createAppeal(AppealRecord appealRecord) {
        return applicationService.createAppeal(appealRecord);
    }

    @Transactional
    @CacheEvict(cacheNames = CACHE, allEntries = true)
    public AppealRecord updateAppeal(AppealRecord appealRecord) {
        return applicationService.updateAppeal(appealRecord);
    }

    /**
     * 供工作流调用的状态更新方法，只改 processStatus 字段
     */
    public AppealRecord updateProcessStatus(Long appealId, AppealProcessState newState) {
        return applicationService.updateProcessStatus(appealId, newState);
    }

    @Transactional
    @CacheEvict(cacheNames = CACHE, allEntries = true)
    public void deleteAppeal(Long appealId) {
        applicationService.deleteAppeal(appealId);
    }

    @Cacheable(cacheNames = CACHE, key = "#appealId", unless = "#result == null")
    public AppealRecord getAppealById(Long appealId) {
        return queryService.getAppealById(appealId);
    }

    @Cacheable(cacheNames = CACHE, key = "'offense:' + #offenseId", unless = "#result.isEmpty()")
    public List<AppealRecord> findByOffenseId(Long offenseId, int page, int size) {
        return queryService.findByOffenseId(offenseId, page, size);
    }

    @Cacheable(cacheNames = CACHE, key = "'appealNumberPrefix:' + #appealNumber + ':' + #page + ':' + #size", unless = "#result == null || #result.isEmpty()")
    public List<AppealRecord> searchByAppealNumberPrefix(String appealNumber, int page, int size) {
        return queryService.searchByAppealNumberPrefix(appealNumber, page, size);
    }

    @Cacheable(cacheNames = CACHE, key = "'appealNumberFuzzy:' + #appealNumber + ':' + #page + ':' + #size", unless = "#result == null || #result.isEmpty()")
    public List<AppealRecord> searchByAppealNumberFuzzy(String appealNumber, int page, int size) {
        return queryService.searchByAppealNumberFuzzy(appealNumber, page, size);
    }

    @Cacheable(cacheNames = CACHE, key = "'appellantNamePrefix:' + #appellantName + ':' + #page + ':' + #size", unless = "#result == null || #result.isEmpty()")
    public List<AppealRecord> searchByAppellantNamePrefix(String appellantName, int page, int size) {
        return queryService.searchByAppellantNamePrefix(appellantName, page, size);
    }

    @Cacheable(cacheNames = CACHE, key = "'appellantNameFuzzy:' + #appellantName + ':' + #page + ':' + #size", unless = "#result == null || #result.isEmpty()")
    public List<AppealRecord> searchByAppellantNameFuzzy(String appellantName, int page, int size) {
        return queryService.searchByAppellantNameFuzzy(appellantName, page, size);
    }

    @Cacheable(cacheNames = CACHE, key = "'appellantIdCard:' + #appellantIdCard + ':' + #page + ':' + #size", unless = "#result == null || #result.isEmpty()")
    public List<AppealRecord> searchByAppellantIdCard(String appellantIdCard, int page, int size) {
        return queryService.searchByAppellantIdCard(appellantIdCard, page, size);
    }

    @Cacheable(cacheNames = CACHE, key = "'acceptanceStatus:' + #acceptanceStatus + ':' + #page + ':' + #size", unless = "#result == null || #result.isEmpty()")
    public List<AppealRecord> searchByAcceptanceStatus(String acceptanceStatus, int page, int size) {
        return queryService.searchByAcceptanceStatus(acceptanceStatus, page, size);
    }

    @Cacheable(cacheNames = CACHE, key = "'processStatus:' + #processStatus + ':' + #page + ':' + #size", unless = "#result == null || #result.isEmpty()")
    public List<AppealRecord> searchByProcessStatus(String processStatus, int page, int size) {
        return queryService.searchByProcessStatus(processStatus, page, size);
    }

    @Cacheable(cacheNames = CACHE, key = "'appealTimeRange:' + #startTime + ':' + #endTime + ':' + #page + ':' + #size", unless = "#result == null || #result.isEmpty()")
    public List<AppealRecord> searchByAppealTimeRange(String startTime, String endTime, int page, int size) {
        return queryService.searchByAppealTimeRange(startTime, endTime, page, size);
    }

    @Cacheable(cacheNames = CACHE, key = "'acceptanceHandler:' + #acceptanceHandler + ':' + #page + ':' + #size", unless = "#result == null || #result.isEmpty()")
    public List<AppealRecord> searchByAcceptanceHandler(String acceptanceHandler, int page, int size) {
        return queryService.searchByAcceptanceHandler(acceptanceHandler, page, size);
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
