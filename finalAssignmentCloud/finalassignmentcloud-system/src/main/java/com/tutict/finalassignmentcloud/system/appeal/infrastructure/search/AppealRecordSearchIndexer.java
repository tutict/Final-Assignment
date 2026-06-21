package com.tutict.finalassignmentcloud.system.appeal.infrastructure.search;

import com.tutict.finalassignmentcloud.entity.appeal.AppealRecord;
import com.tutict.finalassignmentcloud.repository.AppealRecordSearchRepository;
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

    private final AppealRecordSearchRepository appealRecordSearchRepository;

    public AppealRecordSearchIndexer(AppealRecordSearchRepository appealRecordSearchRepository) {
        this.appealRecordSearchRepository = appealRecordSearchRepository;
    }

    public void indexAfterCommit(AppealRecord appealRecord) {
        runAfterCommit(() -> index(appealRecord));
    }

    public void deleteAfterCommit(Long appealId) {
        runAfterCommit(() -> appealRecordSearchRepository.deleteById(appealId));
    }

    public void index(AppealRecord appealRecord) {
        if (appealRecord != null && appealRecord.getAppealId() != null) {
            appealRecordSearchRepository.save(appealRecord);
        }
    }

    public void indexAll(List<AppealRecord> records) {
        if (records == null || records.isEmpty()) {
            return;
        }
        records.stream()
                .filter(Objects::nonNull)
                .filter(record -> record.getAppealId() != null)
                .forEach(appealRecordSearchRepository::save);
    }

    private static void runAfterCommit(Runnable action) {
        if (!TransactionSynchronizationManager.isSynchronizationActive()) {
            action.run();
            return;
        }
        TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
            @Override
            public void afterCommit() {
                action.run();
            }
        });
    }
}
