package com.tutict.finalassignmentbackend.appeal.query;

import com.tutict.finalassignmentbackend.appeal.cache.AppealCachePolicy;
import com.tutict.finalassignmentbackend.appeal.domain.AppealRecordDomainService;
import com.tutict.finalassignmentbackend.appeal.domain.policy.AppealQueryPolicy;
import com.tutict.finalassignmentbackend.appeal.domain.policy.AppealVisibilityPolicy;
import com.tutict.finalassignmentbackend.appeal.query.dto.AppealPageRequest;
import com.tutict.finalassignmentbackend.appeal.read.AppealReadAssembler;
import com.tutict.finalassignmentbackend.appeal.read.AppealReadModel;
import com.tutict.finalassignmentbackend.entity.AppealRecord;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.time.format.DateTimeParseException;
import java.util.List;
import java.util.Optional;
import java.util.function.Supplier;
import java.util.logging.Level;
import java.util.logging.Logger;

@Service
public class AppealRecordQueryService {

    private static final Logger log = Logger.getLogger(AppealRecordQueryService.class.getName());

    private final AppealSearchQueryAdapter searchQueryAdapter;
    private final AppealDbFallbackReader dbFallbackReader;
    private final AppealSearchBackfillService backfillService;
    private final AppealRecordDomainService domainService;
    private final AppealCachePolicy cachePolicy;
    private final AppealQueryConsistencyValidator consistencyValidator;
    private final AppealQueryPolicy queryPolicy;
    private final AppealReadAssembler readAssembler = new AppealReadAssembler();

    public AppealRecordQueryService(
            AppealSearchQueryAdapter searchQueryAdapter,
            AppealDbFallbackReader dbFallbackReader,
            AppealSearchBackfillService backfillService,
            AppealRecordDomainService domainService,
            AppealCachePolicy cachePolicy,
            AppealQueryConsistencyValidator consistencyValidator,
            AppealQueryPolicy queryPolicy
    ) {
        this.searchQueryAdapter = searchQueryAdapter;
        this.dbFallbackReader = dbFallbackReader;
        this.backfillService = backfillService;
        this.domainService = domainService;
        this.cachePolicy = cachePolicy;
        this.consistencyValidator = consistencyValidator;
        this.queryPolicy = queryPolicy;
    }

    public AppealRecord getAppealById(Long appealId) {
        domainService.validateAppealId(appealId);
        AppealVisibilityPolicy.AppealVisibilityContext visibility = queryPolicy.defaultVisibility();
        Optional<AppealRecord> indexed = queryPolicy.visibleRecord(toLegacyRecord(searchQueryAdapter.findById(appealId)), visibility);
        if (queryPolicy.hasIndexedRecord(indexed)) {
            return indexed.get();
        }
        AppealRecord fallback = queryPolicy.visibleRecord(toLegacyRecord(dbFallbackReader.findById(appealId)), visibility);
        consistencyValidator.validateFallbackRecord("getAppealById", fallback);
        cachePolicy.markFallbackRead();
        if (queryPolicy.shouldBackfill(fallback)) {
            backfillService.schedule(fallback);
        }
        return fallback;
    }

    public List<AppealRecord> findByOffenseId(Long offenseId, int page, int size) {
        AppealPageRequest pageRequest = pageRequest(page, size);
        return queryWithFallback(
                "findByOffenseId",
                pageRequest,
                () -> searchQueryAdapter.findByOffenseId(offenseId, pageRequest),
                () -> dbFallbackReader.findByOffenseId(offenseId, pageRequest),
                queryPolicy.offenseVisibility(offenseId)
        );
    }

    public List<AppealRecord> searchByAppealNumberPrefix(String appealNumber, int page, int size) {
        if (queryPolicy.shouldReturnEmptyForTextFilter(appealNumber)) {
            return List.of();
        }
        AppealPageRequest pageRequest = pageRequest(page, size);
        return queryWithFallback(
                "searchByAppealNumberPrefix",
                pageRequest,
                () -> searchQueryAdapter.searchByAppealNumberPrefix(appealNumber, pageRequest),
                () -> dbFallbackReader.searchByAppealNumberPrefix(appealNumber, pageRequest),
                queryPolicy.defaultVisibility()
        );
    }

    public List<AppealRecord> searchByAppealNumberFuzzy(String appealNumber, int page, int size) {
        if (queryPolicy.shouldReturnEmptyForTextFilter(appealNumber)) {
            return List.of();
        }
        AppealPageRequest pageRequest = pageRequest(page, size);
        return queryWithFallback(
                "searchByAppealNumberFuzzy",
                pageRequest,
                () -> searchQueryAdapter.searchByAppealNumberFuzzy(appealNumber, pageRequest),
                () -> dbFallbackReader.searchByAppealNumberFuzzy(appealNumber, pageRequest),
                queryPolicy.defaultVisibility()
        );
    }

    public List<AppealRecord> searchByAppellantNamePrefix(String appellantName, int page, int size) {
        if (queryPolicy.shouldReturnEmptyForTextFilter(appellantName)) {
            return List.of();
        }
        AppealPageRequest pageRequest = pageRequest(page, size);
        return queryWithFallback(
                "searchByAppellantNamePrefix",
                pageRequest,
                () -> searchQueryAdapter.searchByAppellantNamePrefix(appellantName, pageRequest),
                () -> dbFallbackReader.searchByAppellantNamePrefix(appellantName, pageRequest),
                queryPolicy.defaultVisibility()
        );
    }

    public List<AppealRecord> searchByAppellantNameFuzzy(String appellantName, int page, int size) {
        if (queryPolicy.shouldReturnEmptyForTextFilter(appellantName)) {
            return List.of();
        }
        AppealPageRequest pageRequest = pageRequest(page, size);
        return queryWithFallback(
                "searchByAppellantNameFuzzy",
                pageRequest,
                () -> searchQueryAdapter.searchByAppellantNameFuzzy(appellantName, pageRequest),
                () -> dbFallbackReader.searchByAppellantNameFuzzy(appellantName, pageRequest),
                queryPolicy.defaultVisibility()
        );
    }

    public List<AppealRecord> searchByAppellantIdCard(String appellantIdCard, int page, int size) {
        if (queryPolicy.shouldReturnEmptyForTextFilter(appellantIdCard)) {
            return List.of();
        }
        AppealPageRequest pageRequest = pageRequest(page, size);
        return queryWithFallback(
                "searchByAppellantIdCard",
                pageRequest,
                () -> searchQueryAdapter.searchByAppellantIdCard(appellantIdCard, pageRequest),
                () -> dbFallbackReader.searchByAppellantIdCard(appellantIdCard, pageRequest),
                queryPolicy.defaultVisibility()
        );
    }

    public List<AppealRecord> searchByAcceptanceStatus(String acceptanceStatus, int page, int size) {
        if (queryPolicy.shouldReturnEmptyForTextFilter(acceptanceStatus)) {
            return List.of();
        }
        AppealPageRequest pageRequest = pageRequest(page, size);
        return queryWithFallback(
                "searchByAcceptanceStatus",
                pageRequest,
                () -> searchQueryAdapter.searchByAcceptanceStatus(acceptanceStatus, pageRequest),
                () -> dbFallbackReader.searchByAcceptanceStatus(acceptanceStatus, pageRequest),
                queryPolicy.defaultVisibility()
        );
    }

    public List<AppealRecord> searchByProcessStatus(String processStatus, int page, int size) {
        if (queryPolicy.shouldReturnEmptyForTextFilter(processStatus)) {
            return List.of();
        }
        AppealPageRequest pageRequest = pageRequest(page, size);
        return queryWithFallback(
                "searchByProcessStatus",
                pageRequest,
                () -> searchQueryAdapter.searchByProcessStatus(processStatus, pageRequest),
                () -> dbFallbackReader.searchByProcessStatus(processStatus, pageRequest),
                queryPolicy.defaultVisibility()
        );
    }

    public List<AppealRecord> searchByAppealTimeRange(String startTime, String endTime, int page, int size) {
        AppealPageRequest pageRequest = pageRequest(page, size);
        LocalDateTime start = parseDateTime(startTime, "startTime");
        LocalDateTime end = parseDateTime(endTime, "endTime");
        if (queryPolicy.shouldReturnEmptyForTimeRange(start, end)) {
            return List.of();
        }
        return queryWithFallback(
                "searchByAppealTimeRange",
                pageRequest,
                () -> searchQueryAdapter.searchByAppealTimeRange(startTime, endTime, pageRequest),
                () -> dbFallbackReader.searchByAppealTimeRange(start, end, pageRequest),
                queryPolicy.defaultVisibility()
        );
    }

    public List<AppealRecord> searchByAcceptanceHandler(String acceptanceHandler, int page, int size) {
        if (queryPolicy.shouldReturnEmptyForTextFilter(acceptanceHandler)) {
            return List.of();
        }
        AppealPageRequest pageRequest = pageRequest(page, size);
        return queryWithFallback(
                "searchByAcceptanceHandler",
                pageRequest,
                () -> searchQueryAdapter.searchByAcceptanceHandler(acceptanceHandler, pageRequest),
                () -> dbFallbackReader.searchByAcceptanceHandler(acceptanceHandler, pageRequest),
                queryPolicy.defaultVisibility()
        );
    }

    private List<AppealRecord> queryWithFallback(
            String operation,
            AppealPageRequest pageRequest,
            Supplier<List<AppealReadModel>> searchQuery,
            Supplier<List<AppealRecord>> dbFallback,
            AppealVisibilityPolicy.AppealVisibilityContext visibility
    ) {
        List<AppealRecord> indexed = queryPolicy.visibleRecords(toLegacyRecords(searchQuery.get()), visibility);
        if (!queryPolicy.shouldUseDbFallback(indexed)) {
            consistencyValidator.validateSearchResult(operation, pageRequest, indexed);
            return indexed;
        }
        List<AppealRecord> fallback = queryPolicy.visibleRecords(toLegacyRecordsFromEntities(dbFallback.get()), visibility);
        consistencyValidator.validateFallbackResult(operation, pageRequest, indexed, fallback);
        cachePolicy.markFallbackRead();
        if (queryPolicy.shouldBackfill(fallback)) {
            backfillService.scheduleAll(fallback);
        }
        return fallback;
    }

    private AppealPageRequest pageRequest(int page, int size) {
        return new AppealPageRequest(page, size);
    }

    private Optional<AppealRecord> toLegacyRecord(Optional<AppealReadModel> model) {
        return model == null ? Optional.empty() : model.map(readAssembler::toLegacyEntity);
    }

    private AppealRecord toLegacyRecord(AppealRecord entity) {
        return readAssembler.toLegacyEntity(readAssembler.fromEntity(entity));
    }

    private List<AppealRecord> toLegacyRecords(List<AppealReadModel> models) {
        if (models == null || models.isEmpty()) {
            return List.of();
        }
        return models.stream()
                .map(readAssembler::toLegacyEntity)
                .toList();
    }

    private List<AppealRecord> toLegacyRecordsFromEntities(List<AppealRecord> entities) {
        if (entities == null || entities.isEmpty()) {
            return List.of();
        }
        return entities.stream()
                .map(this::toLegacyRecord)
                .toList();
    }

    private LocalDateTime parseDateTime(String value, String fieldName) {
        if (queryPolicy.shouldReturnEmptyForTextFilter(value)) {
            return null;
        }
        try {
            return LocalDateTime.parse(value);
        } catch (DateTimeParseException ex) {
            log.log(Level.WARNING, "Failed to parse " + fieldName + ": " + value, ex);
            return null;
        }
    }

}
