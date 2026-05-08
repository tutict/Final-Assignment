package com.tutict.finalassignmentbackend.appeal.application;

import com.tutict.finalassignmentbackend.appeal.cache.AppealCachePolicy;
import com.tutict.finalassignmentbackend.appeal.domain.AppealRecordDomainService;
import com.tutict.finalassignmentbackend.appeal.domain.idempotency.AppealIdempotencyService;
import com.tutict.finalassignmentbackend.appeal.infrastructure.messaging.TransactionalDomainEventPublisher;
import com.tutict.finalassignmentbackend.appeal.infrastructure.search.AppealRecordSearchIndexer;
import com.tutict.finalassignmentbackend.config.statemachine.states.AppealProcessState;
import com.tutict.finalassignmentbackend.entity.AppealRecord;
import com.tutict.finalassignmentbackend.mapper.AppealRecordMapper;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.Objects;

@Service
public class AppealRecordApplicationService {

    private final AppealRecordMapper appealRecordMapper;
    private final AppealRecordDomainService domainService;
    private final AppealRecordSearchIndexer searchIndexer;
    private final TransactionalDomainEventPublisher eventPublisher;
    private final AppealCachePolicy cachePolicy;
    private final AppealIdempotencyService idempotencyService;

    public AppealRecordApplicationService(
            AppealRecordMapper appealRecordMapper,
            AppealRecordDomainService domainService,
            AppealRecordSearchIndexer searchIndexer,
            TransactionalDomainEventPublisher eventPublisher,
            AppealCachePolicy cachePolicy,
            AppealIdempotencyService idempotencyService
    ) {
        this.appealRecordMapper = appealRecordMapper;
        this.domainService = domainService;
        this.searchIndexer = searchIndexer;
        this.eventPublisher = eventPublisher;
        this.cachePolicy = cachePolicy;
        this.idempotencyService = idempotencyService;
    }

    @Transactional
    public void checkAndInsertIdempotency(String idempotencyKey, AppealRecord appealRecord, String action) {
        Objects.requireNonNull(appealRecord, "Appeal record cannot be null");
        idempotencyService.checkAndInsert(idempotencyKey);
        eventPublisher.publishAppealRecordAfterCommit("appeal_" + action, idempotencyKey, appealRecord);
        idempotencyService.markPendingSuccess(idempotencyKey, appealRecord.getAppealId());
        cachePolicy.onWrite();
    }

    @Transactional
    public AppealRecord createAppeal(AppealRecord appealRecord) {
        domainService.validateAppeal(appealRecord);
        appealRecordMapper.insert(appealRecord);
        searchIndexer.indexAfterCommit(appealRecord);
        cachePolicy.onWrite();
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
        cachePolicy.onWrite();
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
        cachePolicy.onWrite();
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
        cachePolicy.onWrite();
    }

    public boolean shouldSkipProcessing(String idempotencyKey) {
        return idempotencyService.shouldSkipProcessing(idempotencyKey);
    }

    public void markHistorySuccess(String idempotencyKey, Long appealId) {
        idempotencyService.markHistorySuccess(idempotencyKey, appealId);
    }

    public void markHistoryFailure(String idempotencyKey, String reason) {
        idempotencyService.markHistoryFailure(idempotencyKey, reason);
    }
}
