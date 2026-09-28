package com.tutict.finalassignmentbackend.reliability;

import java.util.concurrent.Semaphore;
import org.springframework.stereotype.Component;

/**
 * At most two model calls are in flight in this process.
 * A full gate degrades immediately; callers must not wait.
 */
@Component
public class ModelCallBulkhead {

    public static final int MAX_IN_FLIGHT = 2;

    private final Semaphore permits;

    public ModelCallBulkhead() {
        this(MAX_IN_FLIGHT);
    }

    public ModelCallBulkhead(int permits) {
        if (permits < 0) {
            throw new IllegalArgumentException("permits must be >= 0");
        }
        this.permits = new Semaphore(permits);
    }

    public static ModelCallBulkhead exhausted() {
        return new ModelCallBulkhead(0);
    }

    public boolean tryAcquire() {
        return permits.tryAcquire();
    }

    public void release() {
        permits.release();
    }
}
