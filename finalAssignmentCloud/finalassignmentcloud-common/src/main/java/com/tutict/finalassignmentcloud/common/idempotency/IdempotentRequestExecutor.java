package com.tutict.finalassignmentcloud.common.idempotency;

import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;

import java.util.function.Consumer;
import java.util.function.Supplier;

@Component
public class IdempotentRequestExecutor {

    public <T> IdempotentExecution<T> execute(
            String idempotencyKey,
            Supplier<Boolean> duplicateCheck,
            Runnable registerProcessing,
            ThrowingSupplier<T> action,
            Consumer<T> markSuccess,
            Consumer<Exception> markFailure
    ) {
        boolean keyed = StringUtils.hasText(idempotencyKey);
        try {
            if (keyed) {
                if (duplicateCheck != null && Boolean.TRUE.equals(duplicateCheck.get())) {
                    return IdempotentExecution.skipped();
                }
                if (registerProcessing != null) {
                    registerProcessing.run();
                }
            }
            T result = action.get();
            if (keyed && markSuccess != null) {
                markSuccess.accept(result);
            }
            return IdempotentExecution.completed(result);
        } catch (Exception ex) {
            if (keyed && markFailure != null) {
                markFailure.accept(ex);
            }
            throw propagate(ex);
        }
    }

    private RuntimeException propagate(Exception ex) {
        return ex instanceof RuntimeException runtime ? runtime : new RuntimeException(ex);
    }

    @FunctionalInterface
    public interface ThrowingSupplier<T> {
        T get() throws Exception;
    }
}
