package com.tutict.finalassignmentbackend.appeal.query;

import com.tutict.finalassignmentbackend.appeal.infrastructure.search.AppealRecordSearchIndexer;
import com.tutict.finalassignmentbackend.entity.AppealRecord;
import org.springframework.stereotype.Service;
import org.springframework.transaction.support.TransactionSynchronization;
import org.springframework.transaction.support.TransactionSynchronizationManager;

import java.util.List;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.Executor;
import java.util.logging.Level;
import java.util.logging.Logger;

@Service
public class AppealSearchBackfillService {

    private static final Logger log = Logger.getLogger(AppealSearchBackfillService.class.getName());

    private final AppealRecordSearchIndexer searchIndexer;
    private final Executor executor;

    public AppealSearchBackfillService(AppealRecordSearchIndexer searchIndexer) {
        this(searchIndexer, CompletableFuture.delayedExecutor(0, java.util.concurrent.TimeUnit.MILLISECONDS));
    }

    AppealSearchBackfillService(AppealRecordSearchIndexer searchIndexer, Executor executor) {
        this.searchIndexer = searchIndexer;
        this.executor = executor;
    }

    public void schedule(AppealRecord record) {
        if (record == null) {
            return;
        }
        schedule(() -> searchIndexer.index(record));
    }

    public void scheduleAll(List<AppealRecord> records) {
        if (records == null || records.isEmpty()) {
            return;
        }
        schedule(() -> searchIndexer.indexAll(records));
    }

    private void schedule(Runnable action) {
        Runnable guarded = () -> {
            try {
                action.run();
            } catch (Exception ex) {
                log.log(Level.WARNING, "Appeal search backfill failed", ex);
            }
        };
        if (TransactionSynchronizationManager.isSynchronizationActive()) {
            TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
                @Override
                public void afterCommit() {
                    executor.execute(guarded);
                }
            });
            return;
        }
        executor.execute(guarded);
    }
}
