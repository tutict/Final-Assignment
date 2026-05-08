package com.tutict.finalassignmentbackend.appeal.query;

import com.tutict.finalassignmentbackend.appeal.cache.AppealCachePolicy;
import com.tutict.finalassignmentbackend.appeal.domain.AppealRecordDomainService;
import com.tutict.finalassignmentbackend.appeal.domain.policy.AppealQueryPolicy;
import com.tutict.finalassignmentbackend.appeal.infrastructure.search.AppealRecordSearchIndexer;
import com.tutict.finalassignmentbackend.appeal.query.dto.AppealPageRequest;
import com.tutict.finalassignmentbackend.appeal.read.AppealReadAssembler;
import com.tutict.finalassignmentbackend.appeal.read.AppealReadModel;
import com.tutict.finalassignmentbackend.entity.AppealRecord;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.mockito.InOrder;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.inOrder;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

class AppealRecordQueryServiceTest {

    private static final AppealReadAssembler READ_ASSEMBLER = new AppealReadAssembler();

    @Test
    void esHitReturnsSearchResultWithoutDbFallbackOrBackfill() {
        AppealSearchQueryAdapter searchQueryAdapter = mock(AppealSearchQueryAdapter.class);
        AppealDbFallbackReader dbFallbackReader = mock(AppealDbFallbackReader.class);
        AppealSearchBackfillService backfillService = mock(AppealSearchBackfillService.class);
        AppealCachePolicy cachePolicy = mock(AppealCachePolicy.class);
        AppealRecordQueryService service = service(searchQueryAdapter, dbFallbackReader, backfillService, cachePolicy);
        AppealRecord indexed = appealRecord(10L);

        when(searchQueryAdapter.searchByAppealNumberPrefix(eq("AP"), any(AppealPageRequest.class)))
                .thenReturn(List.of(readModel(indexed)));

        List<AppealRecord> result = service.searchByAppealNumberPrefix("AP", 1, 20);

        assertThat(result).containsExactly(indexed);
        verify(searchQueryAdapter).searchByAppealNumberPrefix(eq("AP"), any(AppealPageRequest.class));
        verifyNoInteractions(dbFallbackReader, backfillService, cachePolicy);
    }

    @Test
    void dbFallbackReturnsRecordsWhenSearchMisses() {
        AppealSearchQueryAdapter searchQueryAdapter = mock(AppealSearchQueryAdapter.class);
        AppealDbFallbackReader dbFallbackReader = mock(AppealDbFallbackReader.class);
        AppealSearchBackfillService backfillService = mock(AppealSearchBackfillService.class);
        AppealCachePolicy cachePolicy = mock(AppealCachePolicy.class);
        AppealRecordQueryService service = service(searchQueryAdapter, dbFallbackReader, backfillService, cachePolicy);
        List<AppealRecord> fallback = List.of(appealRecord(11L));

        when(searchQueryAdapter.findByOffenseId(eq(20L), any(AppealPageRequest.class))).thenReturn(List.of());
        when(dbFallbackReader.findByOffenseId(eq(20L), any(AppealPageRequest.class))).thenReturn(fallback);

        List<AppealRecord> result = service.findByOffenseId(20L, 2, 5);

        assertThat(result).containsExactlyElementsOf(fallback);
        verify(cachePolicy).markFallbackRead();
        verify(backfillService).scheduleAll(fallback);
    }

    @Test
    void esHitAppliesVisibilityBeforeReturningResult() {
        AppealSearchQueryAdapter searchQueryAdapter = mock(AppealSearchQueryAdapter.class);
        AppealDbFallbackReader dbFallbackReader = mock(AppealDbFallbackReader.class);
        AppealSearchBackfillService backfillService = mock(AppealSearchBackfillService.class);
        AppealCachePolicy cachePolicy = mock(AppealCachePolicy.class);
        AppealRecordQueryService service = service(searchQueryAdapter, dbFallbackReader, backfillService, cachePolicy);
        AppealRecord visible = appealRecord(15L);
        AppealRecord deleted = appealRecord(16L);
        deleted.setDeletedAt(LocalDateTime.parse("2026-05-08T12:00:00"));

        when(searchQueryAdapter.findByOffenseId(eq(20L), any(AppealPageRequest.class)))
                .thenReturn(List.of(readModel(deleted), readModel(visible)));

        List<AppealRecord> result = service.findByOffenseId(20L, 1, 20);

        assertThat(result).containsExactly(visible);
        verifyNoInteractions(dbFallbackReader, backfillService, cachePolicy);
    }

    @Test
    void fallbackUsesSameVisibilityRulesBeforeBackfill() {
        AppealSearchQueryAdapter searchQueryAdapter = mock(AppealSearchQueryAdapter.class);
        AppealDbFallbackReader dbFallbackReader = mock(AppealDbFallbackReader.class);
        AppealSearchBackfillService backfillService = mock(AppealSearchBackfillService.class);
        AppealCachePolicy cachePolicy = mock(AppealCachePolicy.class);
        AppealRecordQueryService service = service(searchQueryAdapter, dbFallbackReader, backfillService, cachePolicy);
        AppealRecord searchDeleted = appealRecord(17L);
        searchDeleted.setDeletedAt(LocalDateTime.parse("2026-05-08T12:00:00"));
        AppealRecord fallbackDeleted = appealRecord(18L);
        fallbackDeleted.setDeletedAt(LocalDateTime.parse("2026-05-08T12:00:00"));
        AppealRecord visible = appealRecord(19L);

        when(searchQueryAdapter.findByOffenseId(eq(20L), any(AppealPageRequest.class)))
                .thenReturn(List.of(readModel(searchDeleted)));
        when(dbFallbackReader.findByOffenseId(eq(20L), any(AppealPageRequest.class)))
                .thenReturn(List.of(fallbackDeleted, visible));

        List<AppealRecord> result = service.findByOffenseId(20L, 1, 20);

        assertThat(result).containsExactly(visible);
        verify(cachePolicy).markFallbackRead();
        verify(backfillService).scheduleAll(List.of(visible));
    }

    @Test
    void fallbackByIdTriggersSingleRecordBackfill() {
        AppealSearchQueryAdapter searchQueryAdapter = mock(AppealSearchQueryAdapter.class);
        AppealDbFallbackReader dbFallbackReader = mock(AppealDbFallbackReader.class);
        AppealSearchBackfillService backfillService = mock(AppealSearchBackfillService.class);
        AppealCachePolicy cachePolicy = mock(AppealCachePolicy.class);
        AppealRecordQueryService service = service(searchQueryAdapter, dbFallbackReader, backfillService, cachePolicy);
        AppealRecord fallback = appealRecord(12L);

        when(searchQueryAdapter.findById(12L)).thenReturn(Optional.empty());
        when(dbFallbackReader.findById(12L)).thenReturn(fallback);

        AppealRecord result = service.getAppealById(12L);

        assertThat(result).isEqualTo(fallback);
        verify(cachePolicy).markFallbackRead();
        verify(backfillService).schedule(fallback);
    }

    @Test
    void queryServiceOrchestratesSearchDbBackfillInOrderWithStablePageRequest() {
        AppealSearchQueryAdapter searchQueryAdapter = mock(AppealSearchQueryAdapter.class);
        AppealDbFallbackReader dbFallbackReader = mock(AppealDbFallbackReader.class);
        AppealSearchBackfillService backfillService = mock(AppealSearchBackfillService.class);
        AppealCachePolicy cachePolicy = mock(AppealCachePolicy.class);
        AppealRecordQueryService service = service(searchQueryAdapter, dbFallbackReader, backfillService, cachePolicy);
        List<AppealRecord> fallback = List.of(appealRecord(13L));
        ArgumentCaptor<AppealPageRequest> pageRequest = ArgumentCaptor.forClass(AppealPageRequest.class);

        when(searchQueryAdapter.searchByProcessStatus(eq("PENDING"), any(AppealPageRequest.class))).thenReturn(List.of());
        when(dbFallbackReader.searchByProcessStatus(eq("PENDING"), any(AppealPageRequest.class))).thenReturn(fallback);

        List<AppealRecord> result = service.searchByProcessStatus("PENDING", 3, 10);

        assertThat(result).containsExactlyElementsOf(fallback);
        verify(searchQueryAdapter).searchByProcessStatus(eq("PENDING"), pageRequest.capture());
        assertThat(pageRequest.getValue().page()).isEqualTo(3);
        assertThat(pageRequest.getValue().size()).isEqualTo(10);
        assertThat(pageRequest.getValue().zeroBasedPage()).isEqualTo(2);
        InOrder order = inOrder(searchQueryAdapter, dbFallbackReader, cachePolicy, backfillService);
        order.verify(searchQueryAdapter).searchByProcessStatus(eq("PENDING"), any(AppealPageRequest.class));
        order.verify(dbFallbackReader).searchByProcessStatus(eq("PENDING"), any(AppealPageRequest.class));
        order.verify(cachePolicy).markFallbackRead();
        order.verify(backfillService).scheduleAll(fallback);
    }

    @Test
    void backfillServiceDelegatesToSearchIndexerBestEffort() {
        AppealRecordSearchIndexer searchIndexer = mock(AppealRecordSearchIndexer.class);
        AppealSearchBackfillService backfillService = new AppealSearchBackfillService(searchIndexer, Runnable::run);
        List<AppealRecord> records = List.of(appealRecord(14L));

        backfillService.scheduleAll(records);

        verify(searchIndexer).indexAll(records);
    }

    private static AppealRecordQueryService service(
            AppealSearchQueryAdapter searchQueryAdapter,
            AppealDbFallbackReader dbFallbackReader,
            AppealSearchBackfillService backfillService
    ) {
        return new AppealRecordQueryService(
                searchQueryAdapter,
                dbFallbackReader,
                backfillService,
                new AppealRecordDomainService(),
                mock(AppealCachePolicy.class),
                new AppealQueryConsistencyValidator(false),
                new AppealQueryPolicy()
        );
    }

    private static AppealRecordQueryService service(
            AppealSearchQueryAdapter searchQueryAdapter,
            AppealDbFallbackReader dbFallbackReader,
            AppealSearchBackfillService backfillService,
            AppealCachePolicy cachePolicy
    ) {
        return new AppealRecordQueryService(
                searchQueryAdapter,
                dbFallbackReader,
                backfillService,
                new AppealRecordDomainService(),
                cachePolicy,
                new AppealQueryConsistencyValidator(false),
                new AppealQueryPolicy()
        );
    }

    private static AppealRecord appealRecord(Long appealId) {
        AppealRecord appealRecord = new AppealRecord();
        appealRecord.setAppealId(appealId);
        appealRecord.setOffenseId(20L);
        appealRecord.setAppealNumber("AP-" + appealId);
        return appealRecord;
    }

    private static AppealReadModel readModel(AppealRecord appealRecord) {
        return READ_ASSEMBLER.fromEntity(appealRecord);
    }
}
