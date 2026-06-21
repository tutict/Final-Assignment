package com.tutict.finalassignmentcloud.common.idempotency;

public record IdempotentExecution<T>(boolean duplicate, T result) {

    public static <T> IdempotentExecution<T> skipped() {
        return new IdempotentExecution<>(true, null);
    }

    public static <T> IdempotentExecution<T> completed(T result) {
        return new IdempotentExecution<>(false, result);
    }
}
