package com.tutict.finalassignmentbackend.appeal.infrastructure.search;

import com.tutict.finalassignmentbackend.entity.AppealRecord;
import com.tutict.finalassignmentbackend.entity.elastic.AppealRecordDocument;
import com.tutict.finalassignmentbackend.repository.AppealRecordSearchRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.support.TransactionSynchronization;
import org.springframework.transaction.support.TransactionSynchronizationManager;

import java.util.List;
import java.util.Objects;

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
        AppealRecordDocument doc = AppealRecordDocument.fromEntity(appealRecord);
        if (doc != null) {
            appealRecordSearchRepository.save(doc);
        }
    }

    public void indexAll(List<AppealRecord> records) {
        if (records == null || records.isEmpty()) {
            return;
        }
        records.stream()
                .map(AppealRecordDocument::fromEntity)
                .filter(Objects::nonNull)
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
