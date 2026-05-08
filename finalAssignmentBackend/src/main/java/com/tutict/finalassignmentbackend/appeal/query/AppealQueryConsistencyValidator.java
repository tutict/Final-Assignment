package com.tutict.finalassignmentbackend.appeal.query;

import com.tutict.finalassignmentbackend.appeal.query.dto.AppealPageRequest;
import com.tutict.finalassignmentbackend.entity.AppealRecord;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;

@Service
public class AppealQueryConsistencyValidator {

    private static final Logger log = Logger.getLogger(AppealQueryConsistencyValidator.class.getName());

    private final boolean enabled;

    public AppealQueryConsistencyValidator(
            @Value("${appeal.query.consistency.enabled:false}") boolean enabled
    ) {
        this.enabled = enabled;
    }

    public void validateSearchResult(String operation, AppealPageRequest pageRequest, List<AppealRecord> records) {
        if (!enabled) {
            return;
        }
        validatePagination(operation, pageRequest);
        validateRecords(operation, records);
    }

    public void validateFallbackResult(
            String operation,
            AppealPageRequest pageRequest,
            List<AppealRecord> indexed,
            List<AppealRecord> fallback
    ) {
        if (!enabled) {
            return;
        }
        validatePagination(operation, pageRequest);
        if (indexed != null && !indexed.isEmpty()) {
            log.log(Level.WARNING, "Appeal query fallback used after non-empty ES result: {0}", operation);
        }
        validateRecords(operation, fallback);
    }

    public void validateFallbackRecord(String operation, AppealRecord fallback) {
        if (!enabled || fallback == null) {
            return;
        }
        if (fallback.getAppealId() == null) {
            log.log(Level.WARNING, "Appeal fallback record missing appealId: {0}", operation);
        }
    }

    private void validatePagination(String operation, AppealPageRequest pageRequest) {
        if (pageRequest.page() < 1 || pageRequest.size() < 1 || pageRequest.zeroBasedPage() < 0) {
            log.log(Level.WARNING, "Appeal query pagination inconsistency detected: {0}", operation);
        }
    }

    private void validateRecords(String operation, List<AppealRecord> records) {
        if (records == null) {
            log.log(Level.WARNING, "Appeal query returned null records: {0}", operation);
            return;
        }
        for (AppealRecord record : records) {
            if (record == null || record.getAppealId() == null) {
                log.log(Level.WARNING, "Appeal query returned unstable record shape: {0}", operation);
                return;
            }
        }
    }
}
