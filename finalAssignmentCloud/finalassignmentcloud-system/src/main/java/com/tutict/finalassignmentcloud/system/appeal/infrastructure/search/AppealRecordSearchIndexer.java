package com.tutict.finalassignmentcloud.system.appeal.infrastructure.search;

import com.tutict.finalassignmentcloud.entity.appeal.AppealRecord;
import com.tutict.finalassignmentcloud.repository.AppealRecordSearchRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.support.TransactionSynchronization;
import org.springframework.transaction.support.TransactionSynchronizationManager;

import java.util.List;
import java.util.Objects;

/**
 * Elasticsearch indexer for Appeal records
 * Simplified version using AppealRecord directly instead of separate Document class
 */
@Service
public class AppealRecordSearchIndexer {

    private static final Logger log = LoggerFactory.getLogger(AppealRecordSearchIndexer.class);

    private final AppealRecordSearchRepository appealRecordSearchRepository;

    public AppealRecordSearchIndexer(AppealRecordSearchRepository appealRecordSearchRepository) {
        this.appealRecordSearchRepository = appealRecordSearchRepository;
        log.info("AppealRecordSearchIndexer initialized with repository: {}",
                appealRecordSearchRepository.getClass().getSimpleName());
    }

    public void indexAfterCommit(AppealRecord appealRecord) {
        log.debug("Scheduling index after commit for appealId={}",
                 appealRecord != null ? appealRecord.getAppealId() : null);
        runAfterCommit(() -> index(appealRecord));
    }

    public void deleteAfterCommit(Long appealId) {
        log.debug("Scheduling delete after commit for appealId={}", appealId);
        runAfterCommit(() -> {
            log.info("Deleting appeal from search index: appealId={}", appealId);
            appealRecordSearchRepository.deleteById(appealId);
            log.info("Successfully deleted appeal from search index: appealId={}", appealId);
        });
    }

    public void index(AppealRecord appealRecord) {
        if (appealRecord == null || appealRecord.getAppealId() == null) {
            log.warn("Skipping index: invalid appeal record (null or missing ID)");
            return;
        }

        log.info("Indexing appeal to Elasticsearch: appealId={}, offenseId={}",
                appealRecord.getAppealId(), appealRecord.getOffenseId());

        try {
            appealRecordSearchRepository.save(appealRecord);
            log.info("Successfully indexed appeal: appealId={}", appealRecord.getAppealId());
        } catch (Exception e) {
            log.error("Failed to index appeal: appealId={}, error={}",
                     appealRecord.getAppealId(), e.getMessage(), e);
            throw e;
        }
    }

    public void indexAll(List<AppealRecord> records) {
        if (records == null || records.isEmpty()) {
            log.debug("Skipping indexAll: no records to index");
            return;
        }

        log.info("Bulk indexing {} appeal records to Elasticsearch", records.size());

        long indexed = records.stream()
                .filter(Objects::nonNull)
                .filter(record -> record.getAppealId() != null)
                .peek(record -> log.debug("Indexing appeal in batch: appealId={}", record.getAppealId()))
                .peek(appealRecordSearchRepository::save)
                .count();

        log.info("Successfully bulk indexed {} appeal records", indexed);
    }

    private static void runAfterCommit(Runnable action) {
        if (!TransactionSynchronizationManager.isSynchronizationActive()) {
            log.trace("No active transaction, running action immediately");
            action.run();
            return;
        }

        log.trace("Registering action to run after transaction commit");
        TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
            @Override
            public void afterCommit() {
                log.trace("Transaction committed, executing registered action");
                action.run();
            }
        });
    }
}
