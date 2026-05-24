package com.tutict.finalassignmentbackend.appeal.infrastructure.messaging;

import com.tutict.finalassignmentbackend.appeal.infrastructure.transaction.AfterCommitExecutor;
import com.tutict.finalassignmentbackend.entity.appeal.AppealRecord;
import org.springframework.stereotype.Service;

import java.util.logging.Level;
import java.util.logging.Logger;

@Service
public class TransactionalDomainEventPublisher {

    private static final Logger log = Logger.getLogger(TransactionalDomainEventPublisher.class.getName());

    private final AppealRecordEventPublisher eventPublisher;
    private final AfterCommitExecutor afterCommitExecutor;

    public TransactionalDomainEventPublisher(
            AppealRecordEventPublisher eventPublisher,
            AfterCommitExecutor afterCommitExecutor
    ) {
        this.eventPublisher = eventPublisher;
        this.afterCommitExecutor = afterCommitExecutor;
    }

    public void publishAppealRecordAfterCommit(String topic, String idempotencyKey, AppealRecord appealRecord) {
        afterCommitExecutor.execute(() -> {
            try {
                eventPublisher.publish(topic, idempotencyKey, appealRecord);
            } catch (RuntimeException ex) {
                log.log(Level.WARNING, "Appeal domain event publish failed after commit", ex);
            }
        });
    }
}
