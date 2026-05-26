package com.tutict.finalassignmentbackend.appeal.application;

import com.baomidou.mybatisplus.core.conditions.update.UpdateWrapper;
import com.tutict.finalassignmentbackend.appeal.cache.AppealCachePolicy;
import com.tutict.finalassignmentbackend.appeal.domain.AppealRecordDomainService;
import com.tutict.finalassignmentbackend.appeal.domain.AppealUpdateMergeCoordinator;
import com.tutict.finalassignmentbackend.appeal.domain.idempotency.AppealIdempotencyService;
import com.tutict.finalassignmentbackend.appeal.domain.policy.AppealCallerMetadata;
import com.tutict.finalassignmentbackend.appeal.domain.policy.AppealEventIntentPolicy;
import com.tutict.finalassignmentbackend.appeal.domain.policy.AppealEventMetadata;
import com.tutict.finalassignmentbackend.appeal.domain.policy.AppealEventType;
import com.tutict.finalassignmentbackend.appeal.domain.policy.AppealUpdateIntentPolicy.UpdateIntent;
import com.tutict.finalassignmentbackend.appeal.domain.policy.AppealWorkflowDecisionPolicy;
import com.tutict.finalassignmentbackend.appeal.infrastructure.messaging.TransactionalDomainEventPublisher;
import com.tutict.finalassignmentbackend.appeal.infrastructure.search.AppealRecordSearchIndexer;
import com.tutict.finalassignmentbackend.config.statemachine.states.AppealProcessState;
import com.tutict.finalassignmentbackend.entity.appeal.AppealRecord;
import com.tutict.finalassignmentbackend.entity.offense.OffenseRecord;
import com.tutict.finalassignmentbackend.exception.BusinessException;
import com.tutict.finalassignmentbackend.mapper.appeal.AppealRecordMapper;
import com.tutict.finalassignmentbackend.mapper.offense.OffenseRecordMapper;
import com.tutict.finalassignmentbackend.security.crypto.SensitiveDataPersistenceService;
import com.tutict.finalassignmentbackend.service.events.AppealStatusChangedEvent;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.Objects;

@Service
public class AppealRecordApplicationService {

    private static final AppealCallerMetadata FULL_UPDATE_CALLER =
            AppealCallerMetadata.controller("AppealRecordApplicationService.updateAppeal");
    private static final AppealCallerMetadata WORKFLOW_UPDATE_CALLER =
            AppealCallerMetadata.workflow("AppealRecordApplicationService.updateProcessStatus");
    private static final AppealCallerMetadata SYSTEM_EVENT_CALLER =
            AppealCallerMetadata.system("AppealRecordApplicationService.applyKafkaEvent");

    private final AppealRecordMapper appealRecordMapper;
    private final OffenseRecordMapper offenseRecordMapper;
    private final AppealRecordDomainService domainService;
    private final AppealRecordSearchIndexer searchIndexer;
    private final TransactionalDomainEventPublisher eventPublisher;
    private final AppealCachePolicy cachePolicy;
    private final AppealIdempotencyService idempotencyService;
    private final AppealWorkflowDecisionPolicy workflowDecisionPolicy;
    private final AppealUpdateMergeCoordinator updateMergeCoordinator;
    private final ApplicationEventPublisher applicationEventPublisher;
    private final SensitiveDataPersistenceService sensitiveDataPersistenceService;
    private final AppealEventIntentPolicy eventIntentPolicy = new AppealEventIntentPolicy();

    @Autowired
    public AppealRecordApplicationService(
            AppealRecordMapper appealRecordMapper,
            OffenseRecordMapper offenseRecordMapper,
            AppealRecordDomainService domainService,
            AppealRecordSearchIndexer searchIndexer,
            TransactionalDomainEventPublisher eventPublisher,
            AppealCachePolicy cachePolicy,
            AppealIdempotencyService idempotencyService,
            AppealWorkflowDecisionPolicy workflowDecisionPolicy,
            AppealUpdateMergeCoordinator updateMergeCoordinator,
            ApplicationEventPublisher applicationEventPublisher,
            SensitiveDataPersistenceService sensitiveDataPersistenceService
    ) {
        this.appealRecordMapper = appealRecordMapper;
        this.offenseRecordMapper = offenseRecordMapper;
        this.domainService = domainService;
        this.searchIndexer = searchIndexer;
        this.eventPublisher = eventPublisher;
        this.cachePolicy = cachePolicy;
        this.idempotencyService = idempotencyService;
        this.workflowDecisionPolicy = workflowDecisionPolicy;
        this.updateMergeCoordinator = updateMergeCoordinator;
        this.applicationEventPublisher = applicationEventPublisher;
        this.sensitiveDataPersistenceService = sensitiveDataPersistenceService;
    }

    public AppealRecordApplicationService(
            AppealRecordMapper appealRecordMapper,
            OffenseRecordMapper offenseRecordMapper,
            AppealRecordDomainService domainService,
            AppealRecordSearchIndexer searchIndexer,
            TransactionalDomainEventPublisher eventPublisher,
            AppealCachePolicy cachePolicy,
            AppealIdempotencyService idempotencyService,
            AppealWorkflowDecisionPolicy workflowDecisionPolicy,
            AppealUpdateMergeCoordinator updateMergeCoordinator
    ) {
        this(
                appealRecordMapper,
                offenseRecordMapper,
                domainService,
                searchIndexer,
                eventPublisher,
                cachePolicy,
                idempotencyService,
                workflowDecisionPolicy,
                updateMergeCoordinator,
                event -> {
                },
                null
        );
    }

    public AppealRecordApplicationService(
            AppealRecordMapper appealRecordMapper,
            AppealRecordDomainService domainService,
            AppealRecordSearchIndexer searchIndexer,
            TransactionalDomainEventPublisher eventPublisher,
            AppealCachePolicy cachePolicy,
            AppealIdempotencyService idempotencyService,
            AppealWorkflowDecisionPolicy workflowDecisionPolicy,
            AppealUpdateMergeCoordinator updateMergeCoordinator
    ) {
        this(
                appealRecordMapper,
                null,
                domainService,
                searchIndexer,
                eventPublisher,
                cachePolicy,
                idempotencyService,
                workflowDecisionPolicy,
                updateMergeCoordinator
        );
    }

    @Transactional
    public void checkAndInsertIdempotency(String idempotencyKey, AppealRecord appealRecord, String action) {
        Objects.requireNonNull(appealRecord, "Appeal record cannot be null");
        prepareSensitiveData(appealRecord);
        idempotencyService.checkAndInsert(idempotencyKey);
        AppealEventMetadata eventMetadata = classifyOutboundEvent(appealRecord, action);
        if (eventMetadata.republishesKafka()) {
            eventPublisher.publishAppealRecordAfterCommit("appeal_" + action, idempotencyKey, appealRecord);
        }
        idempotencyService.markPendingSuccess(idempotencyKey, appealRecord.getAppealId());
        if (eventMetadata.evictsCache()) {
            cachePolicy.onWrite();
        }
    }

    @Transactional
    public AppealRecord createAppeal(AppealRecord appealRecord) {
        fillDriverIdFromOffense(appealRecord);
        domainService.validateAppeal(appealRecord);
        prepareSensitiveData(appealRecord);
        appealRecordMapper.insert(appealRecord);
        searchIndexer.indexAfterCommit(appealRecord);
        cachePolicy.onWrite();
        return appealRecord;
    }

    @Transactional
    public AppealRecord updateAppeal(AppealRecord appealRecord) {
        domainService.validateAppealId(appealRecord);
        fillDriverIdFromOffense(appealRecord);
        AppealRecord existing = appealRecordMapper.selectById(appealRecord.getAppealId());
        if (workflowDecisionPolicy.isMissingAppeal(existing)) {
            throw new IllegalStateException("Appeal not found: " + appealRecord.getAppealId());
        }
        if (updateMergeCoordinator.isNoOp(existing, appealRecord, UpdateIntent.FULL_UPDATE)) {
            return existing;
        }
        AppealRecord merged = updateMergeCoordinator.merge(
                existing,
                appealRecord,
                UpdateIntent.FULL_UPDATE,
                FULL_UPDATE_CALLER
        );
        merged.setUpdatedAt(LocalDateTime.now());
        prepareSensitiveData(merged);
        int rows = appealRecordMapper.updateById(merged);
        if (workflowDecisionPolicy.isMissingMutation(rows)) {
            throw new IllegalStateException("Appeal not found: " + appealRecord.getAppealId());
        }
        searchIndexer.indexAfterCommit(merged);
        cachePolicy.onWrite();
        publishAppealStatusChangedIfNeeded(existing, merged);
        return merged;
    }

    @Transactional
    public AppealRecord applyKafkaEvent(AppealRecord appealRecord, String action) {
        Objects.requireNonNull(appealRecord, "Appeal record cannot be null");
        if ("create".equalsIgnoreCase(action)) {
            fillDriverIdFromOffense(appealRecord);
            return createAppeal(appealRecord);
        }
        if (!"update".equalsIgnoreCase(action)) {
            throw new IllegalArgumentException("Unsupported appeal Kafka action: " + action);
        }
        domainService.validateAppealId(appealRecord.getAppealId());
        fillDriverIdFromOffense(appealRecord);
        AppealRecord existing = appealRecordMapper.selectById(appealRecord.getAppealId());
        if (workflowDecisionPolicy.isMissingAppeal(existing)) {
            throw new IllegalStateException("Appeal not found: " + appealRecord.getAppealId());
        }
        AppealEventMetadata eventMetadata = eventIntentPolicy.classify(action, existing, appealRecord, false);
        if (eventMetadata.noOp()) {
            return existing;
        }
        AppealRecord merged = updateMergeCoordinator.merge(
                existing,
                appealRecord,
                eventMetadata.updateIntent(),
                callerFor(eventMetadata)
        );
        merged.setUpdatedAt(LocalDateTime.now());
        prepareSensitiveData(merged);
        int rows = appealRecordMapper.updateById(merged);
        if (workflowDecisionPolicy.isMissingMutation(rows)) {
            throw new IllegalStateException("Appeal not found: " + appealRecord.getAppealId());
        }
        if (eventMetadata.reindexesSearch()) {
            searchIndexer.indexAfterCommit(merged);
        }
        if (eventMetadata.evictsCache()) {
            cachePolicy.onWrite();
        }
        publishAppealStatusChangedIfNeeded(existing, merged);
        return merged;
    }

    @Transactional(rollbackFor = Exception.class)
    public AppealRecord updateProcessStatus(Long appealId, AppealProcessState newState) {
        domainService.validateAppealId(appealId);
        AppealRecord existing = appealRecordMapper.selectById(appealId);
        if (workflowDecisionPolicy.isMissingAppeal(existing)) {
            throw new IllegalStateException("Appeal not found: " + appealId);
        }
        AppealRecord incoming = new AppealRecord();
        incoming.setAppealId(appealId);
        if (newState != null) {
            incoming.setProcessStatus(newState.getCode());
        }
        if (updateMergeCoordinator.isNoOp(existing, incoming, UpdateIntent.WORKFLOW_UPDATE)) {
            return existing;
        }
        AppealRecord merged = updateMergeCoordinator.merge(
                existing,
                incoming,
                UpdateIntent.WORKFLOW_UPDATE,
                WORKFLOW_UPDATE_CALLER
        );
        merged.setUpdatedAt(LocalDateTime.now());
        UpdateWrapper<AppealRecord> updateWrapper = new UpdateWrapper<AppealRecord>()
                .eq("appeal_id", appealId)
                .set("process_status", merged.getProcessStatus())
                .set("updated_at", merged.getUpdatedAt());
        applyAppealStatusPrecondition(updateWrapper, existing.getProcessStatus());
        int rows = appealRecordMapper.update(null, updateWrapper);
        if (workflowDecisionPolicy.isMissingMutation(rows)) {
            throw new BusinessException("CONFLICT", "该记录已被处理，无法重复操作");
        }
        searchIndexer.indexAfterCommit(merged);
        cachePolicy.onWrite();
        publishAppealStatusChangedIfNeeded(existing, merged);
        return merged;
    }

    private void applyAppealStatusPrecondition(UpdateWrapper<AppealRecord> updateWrapper,
                                               String currentProcessStatus) {
        if (currentProcessStatus == null) {
            updateWrapper.isNull("process_status");
        } else {
            updateWrapper.eq("process_status", currentProcessStatus);
        }
    }

    @Transactional
    public void deleteAppeal(Long appealId) {
        domainService.validateAppealId(appealId);
        int rows = appealRecordMapper.deleteById(appealId);
        if (workflowDecisionPolicy.isMissingMutation(rows)) {
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

    private AppealEventMetadata classifyOutboundEvent(AppealRecord appealRecord, String action) {
        if ("create".equalsIgnoreCase(action) || appealRecord.getAppealId() == null) {
            return AppealEventMetadata.outboundFullUpdate();
        }
        if (!"update".equalsIgnoreCase(action)) {
            return eventIntentPolicy.classify(action, null, appealRecord, false);
        }
        AppealRecord existing = appealRecordMapper.selectById(appealRecord.getAppealId());
        if (existing != null && updateMergeCoordinator.isNoOp(existing, appealRecord, UpdateIntent.FULL_UPDATE)) {
            return AppealEventMetadata.noOp(false);
        }
        return AppealEventMetadata.outboundFullUpdate();
    }

    private AppealCallerMetadata callerFor(AppealEventMetadata eventMetadata) {
        if (eventMetadata.eventType() == AppealEventType.WORKFLOW) {
            return WORKFLOW_UPDATE_CALLER;
        }
        if (eventMetadata.eventType() == AppealEventType.SYSTEM) {
            return SYSTEM_EVENT_CALLER;
        }
        return FULL_UPDATE_CALLER;
    }

    private void publishAppealStatusChangedIfNeeded(AppealRecord existing, AppealRecord updated) {
        if (updated == null || isBlank(updated.getProcessStatus())) {
            return;
        }
        String oldStatus = existing == null ? null : existing.getProcessStatus();
        if (Objects.equals(oldStatus, updated.getProcessStatus())) {
            return;
        }
        applicationEventPublisher.publishEvent(new AppealStatusChangedEvent(
                firstNonBlank(updated.getCreatedBy(), existing == null ? null : existing.getCreatedBy(),
                        updated.getAppellantContact(), updated.getAppellantEmail()),
                updated.getAppealId(),
                updated.getProcessStatus(),
                updated.getUpdatedAt()
        ));
    }

    private void prepareSensitiveData(AppealRecord appealRecord) {
        if (sensitiveDataPersistenceService != null) {
            sensitiveDataPersistenceService.prepare(appealRecord);
        }
    }

    private void fillDriverIdFromOffense(AppealRecord appealRecord) {
        if (appealRecord == null || appealRecord.getOffenseId() == null) {
            return;
        }
        if (offenseRecordMapper == null) {
            return;
        }
        OffenseRecord offense = offenseRecordMapper.selectById(appealRecord.getOffenseId());
        if (offense != null) {
            if (appealRecord.getDriverId() != null
                    && offense.getDriverId() != null
                    && !Objects.equals(appealRecord.getDriverId(), offense.getDriverId())) {
                throw new IllegalArgumentException("Appeal driver does not match offense owner");
            }
            if (offense.getDriverId() != null) {
                appealRecord.setDriverId(offense.getDriverId());
            }
        }
    }

    private String firstNonBlank(String... values) {
        for (String value : values) {
            if (!isBlank(value)) {
                return value;
            }
        }
        return null;
    }

    private boolean isBlank(String value) {
        return value == null || value.trim().isEmpty();
    }
}
