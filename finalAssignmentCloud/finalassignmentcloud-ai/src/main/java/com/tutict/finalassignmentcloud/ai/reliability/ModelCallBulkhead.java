package com.tutict.finalassignmentcloud.ai.reliability;

import java.util.concurrent.Semaphore;
import org.springframework.stereotype.Component;

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

    public boolean tryAcquire() {
        return permits.tryAcquire();
    }

    public void release() {
        permits.release();
    }
}
