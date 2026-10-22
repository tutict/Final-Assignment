package com.tutict.finalassignmentcloud.reliability;

/**
 * 幂等控制异常的公共判定。
 *
 * <p>这三类异常表示“本次请求没有执行副作用”：重放、键冲突、处理中。
 * 捕获它们时不能把台账降级为 FAILED，否则会把并发中的请求误判为失败并放行重复执行。
 */
public final class IdempotencyOutcome {

    private IdempotencyOutcome() {
    }

    public static boolean isControl(Throwable ex) {
        return ex instanceof IdempotencyReplayException
                || ex instanceof IdempotencyConflictException
                || ex instanceof IdempotencyInProgressException;
    }
}
