package com.tutict.finalassignmentcloud.common.transaction;

import org.springframework.transaction.support.TransactionSynchronization;
import org.springframework.transaction.support.TransactionSynchronizationManager;

/**
 * 提交后副作用的统一入口。
 *
 * 没有活动事务时直接执行：此时数据库写入已经提交，延迟执行反而会让调用方
 * 拿到 "Transaction synchronization is not active" 的 500。
 */
public final class AfterCommit {

    private AfterCommit() {
    }

    public static void execute(TransactionSynchronization synchronization) {
        if (!TransactionSynchronizationManager.isSynchronizationActive()) {
            synchronization.afterCommit();
            return;
        }
        TransactionSynchronizationManager.registerSynchronization(synchronization);
    }
}
