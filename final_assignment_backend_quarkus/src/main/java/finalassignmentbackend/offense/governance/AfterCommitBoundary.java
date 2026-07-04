package finalassignmentbackend.offense.governance;

import jakarta.enterprise.inject.spi.CDI;
import jakarta.transaction.Status;
import jakarta.transaction.Synchronization;
import jakarta.transaction.TransactionSynchronizationRegistry;

/**
 * 在 JTA 事务提交后执行副作用（Kafka 发布 / 索引刷新等）。
 *
 * <p>Spring 版本基于 {@code TransactionSynchronizationManager}；Quarkus 使用 JTA(Narayana)，
 * 这里通过 {@link TransactionSynchronizationRegistry} 注册 interposed synchronization，
 * 仅在事务 COMMITTED 后触发。若当前无活动事务，则立即执行。
 */
public final class AfterCommitBoundary {

    public void afterCommit(Runnable sideEffect) {
        if (sideEffect == null) {
            return;
        }
        TransactionSynchronizationRegistry registry = registry();
        if (registry == null || registry.getTransactionKey() == null) {
            sideEffect.run();
            return;
        }
        registry.registerInterposedSynchronization(new Synchronization() {
            @Override
            public void beforeCompletion() {
                // no-op
            }

            @Override
            public void afterCompletion(int status) {
                if (status == Status.STATUS_COMMITTED) {
                    sideEffect.run();
                }
            }
        });
    }

    private TransactionSynchronizationRegistry registry() {
        try {
            return CDI.current().select(TransactionSynchronizationRegistry.class).get();
        } catch (RuntimeException ex) {
            return null;
        }
    }
}
