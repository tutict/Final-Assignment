package finalassignmentbackend.reliability;

import jakarta.enterprise.context.ApplicationScoped;

import java.util.concurrent.Semaphore;

@ApplicationScoped
public class ModelCallBulkhead {

    public static final int MAX_IN_FLIGHT = 2;

    private final Semaphore permits = new Semaphore(MAX_IN_FLIGHT);

    public boolean tryAcquire() {
        return permits.tryAcquire();
    }

    public void release() {
        permits.release();
    }
}
