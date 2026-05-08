package com.tutict.finalassignmentbackend.appeal;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentbackend.appeal.application.AppealRecordApplicationService;
import com.tutict.finalassignmentbackend.appeal.application.workflow.AppealWorkflowOrchestrator;
import com.tutict.finalassignmentbackend.appeal.cache.AppealCachePolicy;
import com.tutict.finalassignmentbackend.appeal.domain.AppealRecordDomainService;
import com.tutict.finalassignmentbackend.appeal.domain.idempotency.AppealIdempotencyService;
import com.tutict.finalassignmentbackend.appeal.domain.policy.AppealBusinessPolicy;
import com.tutict.finalassignmentbackend.appeal.domain.policy.AppealWorkflowDecisionPolicy;
import com.tutict.finalassignmentbackend.appeal.infrastructure.cache.AppealRecordCacheService;
import com.tutict.finalassignmentbackend.appeal.infrastructure.messaging.AppealRecordEventPublisher;
import com.tutict.finalassignmentbackend.appeal.infrastructure.messaging.TransactionalDomainEventPublisher;
import com.tutict.finalassignmentbackend.appeal.infrastructure.search.AppealRecordSearchIndexer;
import com.tutict.finalassignmentbackend.appeal.infrastructure.transaction.AfterCommitExecutor;
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

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.eq;
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
                new AppealWorkflowDecisionPolicy()
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
