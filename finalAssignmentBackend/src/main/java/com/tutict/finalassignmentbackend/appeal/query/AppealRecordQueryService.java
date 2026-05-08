package com.tutict.finalassignmentbackend.appeal.query;

import com.tutict.finalassignmentbackend.appeal.domain.AppealRecordDomainService;
import com.tutict.finalassignmentbackend.appeal.query.dto.AppealPageRequest;
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

    public AppealRecordQueryService(
            AppealSearchQueryAdapter searchQueryAdapter,
            AppealDbFallbackReader dbFallbackReader,
            AppealSearchBackfillService backfillService,
            AppealRecordDomainService domainService
    ) {
        this.searchQueryAdapter = searchQueryAdapter;
        this.dbFallbackReader = dbFallbackReader;
        this.backfillService = backfillService;
        this.domainService = domainService;
    }

    public AppealRecord getAppealById(Long appealId) {
        domainService.validateAppealId(appealId);
        Optional<AppealRecord> indexed = searchQueryAdapter.findById(appealId);
        if (indexed.isPresent()) {
            return indexed.get();
        }
        AppealRecord fallback = dbFallbackReader.findById(appealId);
        backfillService.schedule(fallback);
        return fallback;
    }

    public List<AppealRecord> findByOffenseId(Long offenseId, int page, int size) {
        AppealPageRequest pageRequest = new AppealPageRequest(page, size);
        return queryWithFallback(
                () -> searchQueryAdapter.findByOffenseId(offenseId, pageRequest),
                () -> dbFallbackReader.findByOffenseId(offenseId, pageRequest)
        );
    }

    public List<AppealRecord> searchByAppealNumberPrefix(String appealNumber, int page, int size) {
        if (isBlank(appealNumber)) {
            return List.of();
        }
        AppealPageRequest pageRequest = new AppealPageRequest(page, size);
        return queryWithFallback(
                () -> searchQueryAdapter.searchByAppealNumberPrefix(appealNumber, pageRequest),
                () -> dbFallbackReader.searchByAppealNumberPrefix(appealNumber, pageRequest)
        );
    }

    public List<AppealRecord> searchByAppealNumberFuzzy(String appealNumber, int page, int size) {
        if (isBlank(appealNumber)) {
            return List.of();
        }
        AppealPageRequest pageRequest = new AppealPageRequest(page, size);
        return queryWithFallback(
                () -> searchQueryAdapter.searchByAppealNumberFuzzy(appealNumber, pageRequest),
                () -> dbFallbackReader.searchByAppealNumberFuzzy(appealNumber, pageRequest)
        );
    }

    public List<AppealRecord> searchByAppellantNamePrefix(String appellantName, int page, int size) {
        if (isBlank(appellantName)) {
            return List.of();
        }
        AppealPageRequest pageRequest = new AppealPageRequest(page, size);
        return queryWithFallback(
                () -> searchQueryAdapter.searchByAppellantNamePrefix(appellantName, pageRequest),
                () -> dbFallbackReader.searchByAppellantNamePrefix(appellantName, pageRequest)
        );
    }

    public List<AppealRecord> searchByAppellantNameFuzzy(String appellantName, int page, int size) {
        if (isBlank(appellantName)) {
            return List.of();
        }
        AppealPageRequest pageRequest = new AppealPageRequest(page, size);
        return queryWithFallback(
                () -> searchQueryAdapter.searchByAppellantNameFuzzy(appellantName, pageRequest),
                () -> dbFallbackReader.searchByAppellantNameFuzzy(appellantName, pageRequest)
        );
    }

    public List<AppealRecord> searchByAppellantIdCard(String appellantIdCard, int page, int size) {
        if (isBlank(appellantIdCard)) {
            return List.of();
        }
        AppealPageRequest pageRequest = new AppealPageRequest(page, size);
        return queryWithFallback(
                () -> searchQueryAdapter.searchByAppellantIdCard(appellantIdCard, pageRequest),
                () -> dbFallbackReader.searchByAppellantIdCard(appellantIdCard, pageRequest)
        );
    }

    public List<AppealRecord> searchByAcceptanceStatus(String acceptanceStatus, int page, int size) {
        if (isBlank(acceptanceStatus)) {
            return List.of();
        }
        AppealPageRequest pageRequest = new AppealPageRequest(page, size);
        return queryWithFallback(
                () -> searchQueryAdapter.searchByAcceptanceStatus(acceptanceStatus, pageRequest),
                () -> dbFallbackReader.searchByAcceptanceStatus(acceptanceStatus, pageRequest)
        );
    }

    public List<AppealRecord> searchByProcessStatus(String processStatus, int page, int size) {
        if (isBlank(processStatus)) {
            return List.of();
        }
        AppealPageRequest pageRequest = new AppealPageRequest(page, size);
        return queryWithFallback(
                () -> searchQueryAdapter.searchByProcessStatus(processStatus, pageRequest),
                () -> dbFallbackReader.searchByProcessStatus(processStatus, pageRequest)
        );
    }

    public List<AppealRecord> searchByAppealTimeRange(String startTime, String endTime, int page, int size) {
        AppealPageRequest pageRequest = new AppealPageRequest(page, size);
        LocalDateTime start = parseDateTime(startTime, "startTime");
        LocalDateTime end = parseDateTime(endTime, "endTime");
        if (start == null || end == null) {
            return List.of();
        }
        return queryWithFallback(
                () -> searchQueryAdapter.searchByAppealTimeRange(startTime, endTime, pageRequest),
                () -> dbFallbackReader.searchByAppealTimeRange(start, end, pageRequest)
        );
    }

    public List<AppealRecord> searchByAcceptanceHandler(String acceptanceHandler, int page, int size) {
        if (isBlank(acceptanceHandler)) {
            return List.of();
        }
        AppealPageRequest pageRequest = new AppealPageRequest(page, size);
        return queryWithFallback(
                () -> searchQueryAdapter.searchByAcceptanceHandler(acceptanceHandler, pageRequest),
                () -> dbFallbackReader.searchByAcceptanceHandler(acceptanceHandler, pageRequest)
        );
    }

    private List<AppealRecord> queryWithFallback(
            Supplier<List<AppealRecord>> searchQuery,
            Supplier<List<AppealRecord>> dbFallback
    ) {
        List<AppealRecord> indexed = searchQuery.get();
        if (!indexed.isEmpty()) {
            return indexed;
        }
        List<AppealRecord> fallback = dbFallback.get();
        backfillService.scheduleAll(fallback);
        return fallback;
    }

    private LocalDateTime parseDateTime(String value, String fieldName) {
        if (isBlank(value)) {
            return null;
        }
        try {
            return LocalDateTime.parse(value);
        } catch (DateTimeParseException ex) {
            log.log(Level.WARNING, "Failed to parse " + fieldName + ": " + value, ex);
            return null;
        }
    }

    private boolean isBlank(String value) {
        return value == null || value.trim().isEmpty();
    }
}
