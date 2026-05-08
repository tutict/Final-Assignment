package com.tutict.finalassignmentbackend.appeal;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentbackend.appeal.application.AppealRecordApplicationService;
import com.tutict.finalassignmentbackend.appeal.domain.AppealRecordDomainService;
import com.tutict.finalassignmentbackend.appeal.infrastructure.cache.AppealRecordCacheService;
import com.tutict.finalassignmentbackend.appeal.infrastructure.messaging.AppealRecordEventPublisher;
import com.tutict.finalassignmentbackend.appeal.infrastructure.search.AppealRecordSearchIndexer;
import com.tutict.finalassignmentbackend.entity.AppealRecord;
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

class AppealRecordApplicationServiceTest {

    @Test
    void applicationServiceOrchestratesCreateWithoutChangingCrudContract() {
        AppealRecordMapper appealRecordMapper = mock(AppealRecordMapper.class);
        AppealRecordSearchIndexer searchIndexer = mock(AppealRecordSearchIndexer.class);
        AppealRecordEventPublisher eventPublisher = mock(AppealRecordEventPublisher.class);
        AppealRecordCacheService cacheService = mock(AppealRecordCacheService.class);
        AppealRecordApplicationService service = new AppealRecordApplicationService(
                appealRecordMapper,
                mock(SysRequestHistoryMapper.class),
                new AppealRecordDomainService(),
                searchIndexer,
                eventPublisher,
                cacheService
        );
        AppealRecord appeal = appealRecord();

        AppealRecord created = service.createAppeal(appeal);

        assertThat(created).isSameAs(appeal);
        verify(appealRecordMapper).insert(appeal);
        verify(searchIndexer).indexAfterCommit(appeal);
        verify(cacheService).evictAll();
        verifyNoInteractions(eventPublisher);
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

    private static AppealRecord appealRecord() {
        AppealRecord appeal = new AppealRecord();
        appeal.setAppealId(10L);
        appeal.setOffenseId(20L);
        appeal.setAppealNumber("A-10");
        return appeal;
    }
}
