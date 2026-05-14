package com.tutict.finalassignmentbackend.appeal;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentbackend.appeal.application.AppealRecordApplicationService;
import com.tutict.finalassignmentbackend.appeal.application.workflow.AppealWorkflowOrchestrator;
import com.tutict.finalassignmentbackend.appeal.cache.AppealCachePolicy;
import com.tutict.finalassignmentbackend.appeal.domain.AppealRecordDomainService;
import com.tutict.finalassignmentbackend.appeal.domain.AppealUpdateMergeCoordinator;
import com.tutict.finalassignmentbackend.appeal.domain.idempotency.AppealIdempotencyService;
import com.tutict.finalassignmentbackend.appeal.domain.policy.AppealEventIntentPolicy;
import com.tutict.finalassignmentbackend.appeal.domain.policy.AppealEventMetadata;
import com.tutict.finalassignmentbackend.appeal.domain.policy.AppealEventType;
import com.tutict.finalassignmentbackend.appeal.domain.policy.AppealBusinessPolicy;
import com.tutict.finalassignmentbackend.appeal.domain.policy.AppealWorkflowDecisionPolicy;
import com.tutict.finalassignmentbackend.appeal.infrastructure.cache.AppealRecordCacheService;
import com.tutict.finalassignmentbackend.appeal.infrastructure.messaging.AppealRecordEventPublisher;
import com.tutict.finalassignmentbackend.appeal.infrastructure.messaging.TransactionalDomainEventPublisher;
import com.tutict.finalassignmentbackend.appeal.infrastructure.search.AppealRecordSearchIndexer;
import com.tutict.finalassignmentbackend.appeal.infrastructure.transaction.AfterCommitExecutor;
import com.tutict.finalassignmentbackend.config.statemachine.states.AppealProcessState;
import com.tutict.finalassignmentbackend.entity.AppealRecord;
import com.tutict.finalassignmentbackend.entity.SysRequestHistory;
import com.tutict.finalassignmentbackend.entity.elastic.AppealRecordDocument;
import com.tutict.finalassignmentbackend.mapper.AppealRecordMapper;
import com.tutict.finalassignmentbackend.mapper.SysRequestHistoryMapper;
import com.tutict.finalassignmentbackend.repository.AppealRecordSearchRepository;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.springframework.cache.Cache;
import org.springframework.cache.concurrent.ConcurrentMapCacheManager;
import org.springframework.kafka.core.KafkaTemplate;

import java.time.LocalDateTime;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

class AppealRecordApplicationServiceTest {

    @Test
    void applicationServiceOrchestratesCreateWithoutChangingCrudContract() {
        AppealRecordMapper appealRecordMapper = mock(AppealRecordMapper.class);
        AppealRecordSearchIndexer searchIndexer = mock(AppealRecordSearchIndexer.class);
        TransactionalDomainEventPublisher eventPublisher = mock(TransactionalDomainEventPublisher.class);
        AppealCachePolicy cachePolicy = mock(AppealCachePolicy.class);
        AppealIdempotencyService idempotencyService = mock(AppealIdempotencyService.class);
        AppealRecordApplicationService service = new AppealRecordApplicationService(
                appealRecordMapper,
                new AppealRecordDomainService(),
                searchIndexer,
                eventPublisher,
                cachePolicy,
                idempotencyService,
                new AppealWorkflowDecisionPolicy(),
                new AppealUpdateMergeCoordinator()
        );
        AppealRecord appeal = appealRecord();

        AppealRecord created = service.createAppeal(appeal);

        assertThat(created).isSameAs(appeal);
        verify(appealRecordMapper).insert(appeal);
        verify(searchIndexer).indexAfterCommit(appeal);
        verify(cachePolicy).onWrite();
        verifyNoInteractions(eventPublisher);
    }

    @Test
    void workflowOrchestratorDelegatesCreateToApplicationService() {
        AppealRecordApplicationService applicationService = mock(AppealRecordApplicationService.class);
        AppealWorkflowOrchestrator orchestrator = new AppealWorkflowOrchestrator(applicationService);
        AppealRecord appeal = appealRecord();
        when(applicationService.createAppeal(appeal)).thenReturn(appeal);

        AppealRecord created = orchestrator.createAppeal(appeal);

        assertThat(created).isSameAs(appeal);
        verify(applicationService).createAppeal(appeal);
    }

    @Test
    void applicationServiceRejectsInvalidTerminalStatusTransition() {
        AppealRecordMapper appealRecordMapper = mock(AppealRecordMapper.class);
        AppealRecordSearchIndexer searchIndexer = mock(AppealRecordSearchIndexer.class);
        TransactionalDomainEventPublisher eventPublisher = mock(TransactionalDomainEventPublisher.class);
        AppealCachePolicy cachePolicy = mock(AppealCachePolicy.class);
        AppealIdempotencyService idempotencyService = mock(AppealIdempotencyService.class);
        AppealRecordApplicationService service = new AppealRecordApplicationService(
                appealRecordMapper,
                new AppealRecordDomainService(),
                searchIndexer,
                eventPublisher,
                cachePolicy,
                idempotencyService,
                new AppealWorkflowDecisionPolicy(),
                new AppealUpdateMergeCoordinator()
        );
        AppealRecord appeal = appealRecord();
        appeal.setProcessStatus(AppealProcessState.APPROVED.getCode());
        when(appealRecordMapper.selectById(10L)).thenReturn(appeal);

        assertThatThrownBy(() -> service.updateProcessStatus(10L, AppealProcessState.UNDER_REVIEW))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("Invalid appeal status transition");

        verify(appealRecordMapper).selectById(10L);
        verifyNoInteractions(searchIndexer, cachePolicy, eventPublisher, idempotencyService);
    }

    @Test
    void applicationServiceMergesUpdateBeforeIndexing() {
        AppealRecordMapper appealRecordMapper = mock(AppealRecordMapper.class);
        AppealRecordSearchIndexer searchIndexer = mock(AppealRecordSearchIndexer.class);
        TransactionalDomainEventPublisher eventPublisher = mock(TransactionalDomainEventPublisher.class);
        AppealCachePolicy cachePolicy = mock(AppealCachePolicy.class);
        AppealIdempotencyService idempotencyService = mock(AppealIdempotencyService.class);
        AppealRecordApplicationService service = new AppealRecordApplicationService(
                appealRecordMapper,
                new AppealRecordDomainService(),
                searchIndexer,
                eventPublisher,
                cachePolicy,
                idempotencyService,
                new AppealWorkflowDecisionPolicy(),
                new AppealUpdateMergeCoordinator()
        );
        AppealRecord existing = appealRecord();
        existing.setAppellantName("Old Name");
        existing.setProcessStatus(AppealProcessState.UNPROCESSED.getCode());
        AppealRecord incoming = new AppealRecord();
        incoming.setAppealId(10L);
        incoming.setOffenseId(99L);
        incoming.setAppealNumber("ILLEGAL");
        incoming.setAppellantName("New Name");
        incoming.setProcessStatus(AppealProcessState.APPROVED.getCode());
        when(appealRecordMapper.selectById(10L)).thenReturn(existing);
        when(appealRecordMapper.updateById(org.mockito.ArgumentMatchers.any(AppealRecord.class))).thenReturn(1);
        ArgumentCaptor<AppealRecord> merged = ArgumentCaptor.forClass(AppealRecord.class);

        AppealRecord updated = service.updateAppeal(incoming);

        verify(appealRecordMapper).updateById(merged.capture());
        verify(searchIndexer).indexAfterCommit(merged.getValue());
        verify(cachePolicy).onWrite();
        assertThat(updated).isSameAs(merged.getValue());
        assertThat(merged.getValue().getAppealId()).isEqualTo(10L);
        assertThat(merged.getValue().getOffenseId()).isEqualTo(20L);
        assertThat(merged.getValue().getAppealNumber()).isEqualTo("A-10");
        assertThat(merged.getValue().getAppellantName()).isEqualTo("New Name");
        assertThat(merged.getValue().getProcessStatus()).isEqualTo(AppealProcessState.UNPROCESSED.getCode());
    }

    @Test
    void applicationServiceUsesWorkflowIntentWithoutBusinessOverwrite() {
        AppealRecordMapper appealRecordMapper = mock(AppealRecordMapper.class);
        AppealRecordSearchIndexer searchIndexer = mock(AppealRecordSearchIndexer.class);
        TransactionalDomainEventPublisher eventPublisher = mock(TransactionalDomainEventPublisher.class);
        AppealCachePolicy cachePolicy = mock(AppealCachePolicy.class);
        AppealIdempotencyService idempotencyService = mock(AppealIdempotencyService.class);
        AppealRecordApplicationService service = new AppealRecordApplicationService(
                appealRecordMapper,
                new AppealRecordDomainService(),
                searchIndexer,
                eventPublisher,
                cachePolicy,
                idempotencyService,
                new AppealWorkflowDecisionPolicy(),
                new AppealUpdateMergeCoordinator()
        );
        AppealRecord existing = appealRecord();
        existing.setAppellantName("Stable Name");
        existing.setProcessStatus(AppealProcessState.UNPROCESSED.getCode());
        when(appealRecordMapper.selectById(10L)).thenReturn(existing);
        when(appealRecordMapper.update(org.mockito.ArgumentMatchers.isNull(), org.mockito.ArgumentMatchers.any())).thenReturn(1);

        AppealRecord updated = service.updateProcessStatus(10L, AppealProcessState.UNDER_REVIEW);

        verify(appealRecordMapper).update(org.mockito.ArgumentMatchers.isNull(), org.mockito.ArgumentMatchers.any());
        verify(searchIndexer).indexAfterCommit(updated);
        verify(cachePolicy).onWrite();
        assertThat(updated.getAppellantName()).isEqualTo("Stable Name");
        assertThat(updated.getProcessStatus()).isEqualTo(AppealProcessState.UNDER_REVIEW.getCode());
    }

    @Test
    void duplicateWorkflowUpdateSkipsDbAndAfterCommitSideEffects() {
        AppealRecordMapper appealRecordMapper = mock(AppealRecordMapper.class);
        AppealRecordSearchIndexer searchIndexer = mock(AppealRecordSearchIndexer.class);
        TransactionalDomainEventPublisher eventPublisher = mock(TransactionalDomainEventPublisher.class);
        AppealCachePolicy cachePolicy = mock(AppealCachePolicy.class);
        AppealIdempotencyService idempotencyService = mock(AppealIdempotencyService.class);
        AppealRecordApplicationService service = new AppealRecordApplicationService(
                appealRecordMapper,
                new AppealRecordDomainService(),
                searchIndexer,
                eventPublisher,
                cachePolicy,
                idempotencyService,
                new AppealWorkflowDecisionPolicy(),
                new AppealUpdateMergeCoordinator()
        );
        AppealRecord existing = appealRecord();
        existing.setProcessStatus(AppealProcessState.UNPROCESSED.getCode());
        when(appealRecordMapper.selectById(10L)).thenReturn(existing);

        AppealRecord returned = service.updateProcessStatus(10L, AppealProcessState.UNPROCESSED);

        assertThat(returned).isSameAs(existing);
        verify(appealRecordMapper).selectById(10L);
        verify(appealRecordMapper, org.mockito.Mockito.never()).updateById(org.mockito.ArgumentMatchers.any(AppealRecord.class));
        verifyNoInteractions(searchIndexer, cachePolicy, eventPublisher, idempotencyService);
    }

    @Test
    void duplicateWorkflowKafkaEventIsNoOpAndSkipsDbSearchAndCache() {
        AppealRecordMapper appealRecordMapper = mock(AppealRecordMapper.class);
        AppealRecordSearchIndexer searchIndexer = mock(AppealRecordSearchIndexer.class);
        TransactionalDomainEventPublisher eventPublisher = mock(TransactionalDomainEventPublisher.class);
        AppealCachePolicy cachePolicy = mock(AppealCachePolicy.class);
        AppealIdempotencyService idempotencyService = mock(AppealIdempotencyService.class);
        AppealRecordApplicationService service = new AppealRecordApplicationService(
                appealRecordMapper,
                new AppealRecordDomainService(),
                searchIndexer,
                eventPublisher,
                cachePolicy,
                idempotencyService,
                new AppealWorkflowDecisionPolicy(),
                new AppealUpdateMergeCoordinator()
        );
        AppealRecord existing = appealRecord();
        existing.setProcessStatus(AppealProcessState.UNDER_REVIEW.getCode());
        AppealRecord incoming = new AppealRecord();
        incoming.setAppealId(10L);
        incoming.setProcessStatus(AppealProcessState.UNDER_REVIEW.getCode());
        when(appealRecordMapper.selectById(10L)).thenReturn(existing);

        AppealEventMetadata duplicateMetadata = new AppealEventIntentPolicy()
                .classify("update", existing, incoming, true);
        AppealRecord returned = service.applyKafkaEvent(incoming, "update");

        assertThat(duplicateMetadata.eventType()).isEqualTo(AppealEventType.NO_OP);
        assertThat(duplicateMetadata.duplicate()).isTrue();
        assertThat(duplicateMetadata.mutatesDatabase()).isFalse();
        assertThat(duplicateMetadata.reindexesSearch()).isFalse();
        assertThat(duplicateMetadata.evictsCache()).isFalse();
        assertThat(returned).isSameAs(existing);
        verify(appealRecordMapper).selectById(10L);
        verify(appealRecordMapper, never()).updateById(org.mockito.ArgumentMatchers.any(AppealRecord.class));
        verifyNoInteractions(searchIndexer, cachePolicy, eventPublisher, idempotencyService);
    }

    @Test
    void staleWorkflowKafkaEventIsRejectedBeforeDbSearchAndCacheSideEffects() {
        AppealRecordMapper appealRecordMapper = mock(AppealRecordMapper.class);
        AppealRecordSearchIndexer searchIndexer = mock(AppealRecordSearchIndexer.class);
        TransactionalDomainEventPublisher eventPublisher = mock(TransactionalDomainEventPublisher.class);
        AppealCachePolicy cachePolicy = mock(AppealCachePolicy.class);
        AppealIdempotencyService idempotencyService = mock(AppealIdempotencyService.class);
        AppealRecordApplicationService service = new AppealRecordApplicationService(
                appealRecordMapper,
                new AppealRecordDomainService(),
                searchIndexer,
                eventPublisher,
                cachePolicy,
                idempotencyService,
                new AppealWorkflowDecisionPolicy(),
                new AppealUpdateMergeCoordinator()
        );
        AppealRecord existing = appealRecord();
        existing.setProcessStatus(AppealProcessState.UNPROCESSED.getCode());
        existing.setUpdatedAt(LocalDateTime.parse("2026-05-08T14:00:00"));
        AppealRecord incoming = new AppealRecord();
        incoming.setAppealId(10L);
        incoming.setProcessStatus(AppealProcessState.UNDER_REVIEW.getCode());
        incoming.setUpdatedAt(LocalDateTime.parse("2026-05-08T13:59:00"));
        when(appealRecordMapper.selectById(10L)).thenReturn(existing);

        assertThatThrownBy(() -> service.applyKafkaEvent(incoming, "update"))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("Stale appeal update rejected");

        verify(appealRecordMapper).selectById(10L);
        verify(appealRecordMapper, never()).updateById(org.mockito.ArgumentMatchers.any(AppealRecord.class));
        verifyNoInteractions(searchIndexer, cachePolicy, eventPublisher, idempotencyService);
    }

    @Test
    void fullUpdateKafkaEventMutatesBusinessFieldsAndTriggersAfterCommitSideEffects() {
        AppealRecordMapper appealRecordMapper = mock(AppealRecordMapper.class);
        AppealRecordSearchIndexer searchIndexer = mock(AppealRecordSearchIndexer.class);
        TransactionalDomainEventPublisher eventPublisher = mock(TransactionalDomainEventPublisher.class);
        AppealCachePolicy cachePolicy = mock(AppealCachePolicy.class);
        AppealIdempotencyService idempotencyService = mock(AppealIdempotencyService.class);
        AppealRecordApplicationService service = new AppealRecordApplicationService(
                appealRecordMapper,
                new AppealRecordDomainService(),
                searchIndexer,
                eventPublisher,
                cachePolicy,
                idempotencyService,
                new AppealWorkflowDecisionPolicy(),
                new AppealUpdateMergeCoordinator()
        );
        AppealRecord existing = appealRecord();
        existing.setAppellantName("Old Name");
        existing.setProcessStatus(AppealProcessState.UNPROCESSED.getCode());
        AppealRecord incoming = new AppealRecord();
        incoming.setAppealId(10L);
        incoming.setAppellantName("New Name");
        when(appealRecordMapper.selectById(10L)).thenReturn(existing);
        when(appealRecordMapper.updateById(org.mockito.ArgumentMatchers.any(AppealRecord.class))).thenReturn(1);
        ArgumentCaptor<AppealRecord> merged = ArgumentCaptor.forClass(AppealRecord.class);

        AppealRecord updated = service.applyKafkaEvent(incoming, "update");

        verify(appealRecordMapper).updateById(merged.capture());
        verify(searchIndexer).indexAfterCommit(merged.getValue());
        verify(cachePolicy).onWrite();
        verifyNoInteractions(eventPublisher, idempotencyService);
        assertThat(updated).isSameAs(merged.getValue());
        assertThat(merged.getValue().getAppellantName()).isEqualTo("New Name");
        assertThat(merged.getValue().getProcessStatus()).isEqualTo(AppealProcessState.UNPROCESSED.getCode());
    }

    @Test
    void workflowOnlyKafkaEventMutatesWorkflowFieldsWithoutBusinessOverwrite() {
        AppealRecordMapper appealRecordMapper = mock(AppealRecordMapper.class);
        AppealRecordSearchIndexer searchIndexer = mock(AppealRecordSearchIndexer.class);
        TransactionalDomainEventPublisher eventPublisher = mock(TransactionalDomainEventPublisher.class);
        AppealCachePolicy cachePolicy = mock(AppealCachePolicy.class);
        AppealIdempotencyService idempotencyService = mock(AppealIdempotencyService.class);
        AppealRecordApplicationService service = new AppealRecordApplicationService(
                appealRecordMapper,
                new AppealRecordDomainService(),
                searchIndexer,
                eventPublisher,
                cachePolicy,
                idempotencyService,
                new AppealWorkflowDecisionPolicy(),
                new AppealUpdateMergeCoordinator()
        );
        AppealRecord existing = appealRecord();
        existing.setAppellantName("Stable Name");
        existing.setProcessStatus(AppealProcessState.UNPROCESSED.getCode());
        AppealRecord incoming = new AppealRecord();
        incoming.setAppealId(10L);
        incoming.setProcessStatus(AppealProcessState.UNDER_REVIEW.getCode());
        when(appealRecordMapper.selectById(10L)).thenReturn(existing);
        when(appealRecordMapper.updateById(org.mockito.ArgumentMatchers.any(AppealRecord.class))).thenReturn(1);
        ArgumentCaptor<AppealRecord> merged = ArgumentCaptor.forClass(AppealRecord.class);

        AppealRecord updated = service.applyKafkaEvent(incoming, "update");

        verify(appealRecordMapper).updateById(merged.capture());
        verify(searchIndexer).indexAfterCommit(merged.getValue());
        verify(cachePolicy).onWrite();
        verifyNoInteractions(eventPublisher, idempotencyService);
        assertThat(updated).isSameAs(merged.getValue());
        assertThat(merged.getValue().getAppellantName()).isEqualTo("Stable Name");
        assertThat(merged.getValue().getProcessStatus()).isEqualTo(AppealProcessState.UNDER_REVIEW.getCode());
    }

    @Test
    void noOpUpdateEventSuppressesKafkaRepublishSearchAndCacheSideEffects() {
        AppealRecordMapper appealRecordMapper = mock(AppealRecordMapper.class);
        AppealRecordSearchIndexer searchIndexer = mock(AppealRecordSearchIndexer.class);
        TransactionalDomainEventPublisher eventPublisher = mock(TransactionalDomainEventPublisher.class);
        AppealCachePolicy cachePolicy = mock(AppealCachePolicy.class);
        AppealIdempotencyService idempotencyService = mock(AppealIdempotencyService.class);
        AppealRecordApplicationService service = new AppealRecordApplicationService(
                appealRecordMapper,
                new AppealRecordDomainService(),
                searchIndexer,
                eventPublisher,
                cachePolicy,
                idempotencyService,
                new AppealWorkflowDecisionPolicy(),
                new AppealUpdateMergeCoordinator()
        );
        AppealRecord existing = appealRecord();
        existing.setAppellantName("Same Name");
        AppealRecord incoming = new AppealRecord();
        incoming.setAppealId(10L);
        incoming.setOffenseId(20L);
        incoming.setAppellantName("Same Name");
        when(appealRecordMapper.selectById(10L)).thenReturn(existing);

        service.checkAndInsertIdempotency("key-noop", incoming, "update");
        AppealRecord returned = service.updateAppeal(incoming);

        assertThat(returned).isSameAs(existing);
        verify(idempotencyService).checkAndInsert("key-noop");
        verify(idempotencyService).markPendingSuccess("key-noop", 10L);
        verify(eventPublisher, never()).publishAppealRecordAfterCommit(
                org.mockito.ArgumentMatchers.anyString(),
                org.mockito.ArgumentMatchers.anyString(),
                org.mockito.ArgumentMatchers.any(AppealRecord.class)
        );
        verify(appealRecordMapper, never()).updateById(org.mockito.ArgumentMatchers.any(AppealRecord.class));
        verifyNoInteractions(searchIndexer, cachePolicy);
    }

    @Test
    void idempotencyServiceKeepsExistingHistorySemantics() {
        SysRequestHistoryMapper mapper = mock(SysRequestHistoryMapper.class);
        AppealIdempotencyService service = new AppealIdempotencyService(mapper, new AppealBusinessPolicy());
        SysRequestHistory history = new SysRequestHistory();
        history.setBusinessStatus("SUCCESS");
        history.setRequestParams("DONE");

        when(mapper.selectByIdempotencyKey("key-1")).thenReturn(null, history);

        service.checkAndInsert("key-1");
        boolean shouldSkip = service.shouldSkipProcessing("key-1");

        verify(mapper).insert(org.mockito.ArgumentMatchers.any(SysRequestHistory.class));
        assertThat(shouldSkip).isTrue();
    }

    @Test
    void eventPublisherSendsSerializedAppealRecord() {
        @SuppressWarnings("unchecked")
        KafkaTemplate<String, String> kafkaTemplate = mock(KafkaTemplate.class);
        AppealRecordEventPublisher publisher = new AppealRecordEventPublisher(
                kafkaTemplate,
                new ObjectMapper().findAndRegisterModules()
        );
        ArgumentCaptor<String> payload = ArgumentCaptor.forClass(String.class);

        publisher.publish("appeal_create", "key-1", appealRecord());

        verify(kafkaTemplate).send(eq("appeal_create"), eq("key-1"), payload.capture());
        assertThat(payload.getValue()).contains("\"appealId\":10");
        assertThat(payload.getValue()).contains("\"offenseId\":20");
    }

    @Test
    void searchIndexerDelegatesToRepository() {
        AppealRecordSearchRepository repository = mock(AppealRecordSearchRepository.class);
        AppealRecordSearchIndexer indexer = new AppealRecordSearchIndexer(repository);
        ArgumentCaptor<AppealRecordDocument> document = ArgumentCaptor.forClass(AppealRecordDocument.class);

        indexer.index(appealRecord());

        verify(repository).save(document.capture());
        assertThat(document.getValue().getAppealId()).isEqualTo(10L);
        assertThat(document.getValue().getOffenseId()).isEqualTo(20L);
    }

    @Test
    void cacheServiceClearsAppealRecordCache() {
        ConcurrentMapCacheManager cacheManager = new ConcurrentMapCacheManager(AppealRecordCacheService.CACHE_NAME);
        Cache cache = cacheManager.getCache(AppealRecordCacheService.CACHE_NAME);
        assertThat(cache).isNotNull();
        cache.put("appeal:10", appealRecord());

        new AppealRecordCacheService(cacheManager).evictAll();

        assertThat(cache.get("appeal:10")).isNull();
    }

    @Test
    void cachePolicyEvictsAfterWriteThroughSingleEntryPoint() {
        AppealRecordCacheService cacheService = mock(AppealRecordCacheService.class);
        AppealCachePolicy cachePolicy = new AppealCachePolicy(cacheService, new AfterCommitExecutor());

        cachePolicy.onWrite();

        verify(cacheService).evictAll();
        assertThat(cachePolicy.writeEvictionStrategy()).isEqualTo(AppealCachePolicy.EvictionStrategy.ON_WRITE_AFTER_COMMIT);
    }

    @Test
    void cachePolicySkipsFallbackCachePutOnce() {
        AppealRecordCacheService cacheService = mock(AppealRecordCacheService.class);
        AppealCachePolicy cachePolicy = new AppealCachePolicy(cacheService, new AfterCommitExecutor());

        cachePolicy.markFallbackRead();

        assertThat(cachePolicy.shouldSkipCache(appealRecord())).isTrue();
        assertThat(cachePolicy.shouldSkipCache(appealRecord())).isFalse();
    }

    private static AppealRecord appealRecord() {
        AppealRecord appeal = new AppealRecord();
        appeal.setAppealId(10L);
        appeal.setOffenseId(20L);
        appeal.setAppealNumber("A-10");
        return appeal;
    }
}
