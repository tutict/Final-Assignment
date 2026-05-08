package com.tutict.finalassignmentbackend.appeal.application;

import com.tutict.finalassignmentbackend.appeal.domain.AppealRecordDomainService;
import com.tutict.finalassignmentbackend.appeal.infrastructure.cache.AppealRecordCacheService;
import com.tutict.finalassignmentbackend.appeal.infrastructure.messaging.AppealRecordEventPublisher;
import com.tutict.finalassignmentbackend.appeal.infrastructure.search.AppealRecordSearchIndexer;
import com.tutict.finalassignmentbackend.config.statemachine.states.AppealProcessState;
import com.tutict.finalassignmentbackend.entity.AppealRecord;
import com.tutict.finalassignmentbackend.entity.SysRequestHistory;
import com.tutict.finalassignmentbackend.mapper.AppealRecordMapper;
import com.tutict.finalassignmentbackend.mapper.SysRequestHistoryMapper;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.Objects;
import java.util.logging.Level;
import java.util.logging.Logger;

@Service
public class AppealRecordApplicationService {

    private static final Logger log = Logger.getLogger(AppealRecordApplicationService.class.getName());

    private final AppealRecordMapper appealRecordMapper;
    private final SysRequestHistoryMapper sysRequestHistoryMapper;
    private final AppealRecordDomainService domainService;
    private final AppealRecordSearchIndexer searchIndexer;
    private final AppealRecordEventPublisher eventPublisher;
    private final AppealRecordCacheService cacheService;

    public AppealRecordApplicationService(
            AppealRecordMapper appealRecordMapper,
            SysRequestHistoryMapper sysRequestHistoryMapper,
            AppealRecordDomainService domainService,
            AppealRecordSearchIndexer searchIndexer,
            AppealRecordEventPublisher eventPublisher,
            AppealRecordCacheService cacheService
    ) {
        this.appealRecordMapper = appealRecordMapper;
        this.sysRequestHistoryMapper = sysRequestHistoryMapper;
        this.domainService = domainService;
        this.searchIndexer = searchIndexer;
        this.eventPublisher = eventPublisher;
        this.cacheService = cacheService;
    }

    @Transactional
    public void checkAndInsertIdempotency(String idempotencyKey, AppealRecord appealRecord, String action) {
        Objects.requireNonNull(appealRecord, "Appeal record cannot be null");
        SysRequestHistory history = sysRequestHistoryMapper.selectByIdempotencyKey(idempotencyKey);
        if (history != null) {
            throw new RuntimeException("Duplicate appeal request detected");
        }

        SysRequestHistory newHistory = buildHistory(idempotencyKey);
        sysRequestHistoryMapper.insert(newHistory);
        eventPublisher.publishAfterCommit("appeal_" + action, idempotencyKey, appealRecord);
        newHistory.setBusinessStatus("SUCCESS");
        newHistory.setBusinessId(appealRecord.getAppealId());
        newHistory.setRequestParams("PENDING");
        newHistory.setUpdatedAt(LocalDateTime.now());
        sysRequestHistoryMapper.updateById(newHistory);
        cacheService.evictAll();
    }

    @Transactional
    public AppealRecord createAppeal(AppealRecord appealRecord) {
        domainService.validateAppeal(appealRecord);
        appealRecordMapper.insert(appealRecord);
        searchIndexer.indexAfterCommit(appealRecord);
        cacheService.evictAll();
        return appealRecord;
    }

    @Transactional
    public AppealRecord updateAppeal(AppealRecord appealRecord) {
        domainService.validateAppealId(appealRecord);
        int rows = appealRecordMapper.updateById(appealRecord);
        if (rows == 0) {
            throw new IllegalStateException("Appeal not found: " + appealRecord.getAppealId());
        }
        searchIndexer.indexAfterCommit(appealRecord);
        cacheService.evictAll();
        return appealRecord;
    }

    public AppealRecord updateProcessStatus(Long appealId, AppealProcessState newState) {
        domainService.validateAppealId(appealId);
        AppealRecord existing = appealRecordMapper.selectById(appealId);
        if (existing == null) {
            throw new IllegalStateException("Appeal not found: " + appealId);
        }
        existing.setProcessStatus(newState != null ? newState.getCode() : existing.getProcessStatus());
        existing.setUpdatedAt(LocalDateTime.now());
        appealRecordMapper.updateById(existing);
        searchIndexer.indexAfterCommit(existing);
        cacheService.evictAll();
        return existing;
    }

    @Transactional
    public void deleteAppeal(Long appealId) {
        domainService.validateAppealId(appealId);
        int rows = appealRecordMapper.deleteById(appealId);
        if (rows == 0) {
            throw new IllegalStateException("Appeal not found: " + appealId);
        }
        searchIndexer.deleteAfterCommit(appealId);
        cacheService.evictAll();
    }

    public boolean shouldSkipProcessing(String idempotencyKey) {
        SysRequestHistory history = sysRequestHistoryMapper.selectByIdempotencyKey(idempotencyKey);
        return history != null
                && "SUCCESS".equalsIgnoreCase(history.getBusinessStatus())
                && "DONE".equalsIgnoreCase(history.getRequestParams());
    }

    public void markHistorySuccess(String idempotencyKey, Long appealId) {
        SysRequestHistory history = sysRequestHistoryMapper.selectByIdempotencyKey(idempotencyKey);
        if (history == null) {
            log.log(Level.WARNING, "Cannot mark success for missing idempotency key {0}", idempotencyKey);
            return;
        }
        history.setBusinessStatus("SUCCESS");
        history.setBusinessId(appealId);
        history.setRequestParams("DONE");
        history.setUpdatedAt(LocalDateTime.now());
        sysRequestHistoryMapper.updateById(history);
    }

    public void markHistoryFailure(String idempotencyKey, String reason) {
        SysRequestHistory history = sysRequestHistoryMapper.selectByIdempotencyKey(idempotencyKey);
        if (history == null) {
            log.log(Level.WARNING, "Cannot mark failure for missing idempotency key {0}", idempotencyKey);
            return;
        }
        history.setBusinessStatus("FAILED");
        history.setRequestParams(truncate(reason));
        history.setUpdatedAt(LocalDateTime.now());
        sysRequestHistoryMapper.updateById(history);
    }

    private SysRequestHistory buildHistory(String key) {
        SysRequestHistory history = new SysRequestHistory();
        history.setIdempotencyKey(key);
        history.setBusinessStatus("PROCESSING");
        history.setCreatedAt(LocalDateTime.now());
        history.setUpdatedAt(LocalDateTime.now());
        return history;
    }

    private String truncate(String value) {
        if (value == null) {
            return null;
        }
        return value.length() <= 500 ? value : value.substring(0, 500);
    }
}
