package finalassignmentbackend.reliability;

import jakarta.enterprise.context.ApplicationScoped;

import java.util.concurrent.atomic.AtomicLong;

@ApplicationScoped
public class ReliabilityMetrics {

    private final AtomicLong loadShed = new AtomicLong();
    private final AtomicLong idempotencyConflict = new AtomicLong();
    private final AtomicLong dependencyTimeout = new AtomicLong();
    private final AtomicLong kafkaPublishFailed = new AtomicLong();
    private final AtomicLong aiFallback = new AtomicLong();
    private final AtomicLong http2xx = new AtomicLong();
    private final AtomicLong http4xx = new AtomicLong();
    private final AtomicLong http5xx = new AtomicLong();

    public void loadShed() { loadShed.incrementAndGet(); }
    public void idempotencyConflict() { idempotencyConflict.incrementAndGet(); }
    public void dependencyTimeout() { dependencyTimeout.incrementAndGet(); }
    public void kafkaPublishFailed() { kafkaPublishFailed.incrementAndGet(); }
    public void aiFallback() { aiFallback.incrementAndGet(); }

    public void noteStatus(int status) {
        if (status >= 200 && status < 300) {
            http2xx.incrementAndGet();
        } else if (status >= 400 && status < 500) {
            http4xx.incrementAndGet();
        } else if (status >= 500 && status < 600) {
            http5xx.incrementAndGet();
        }
    }

    public String prometheus(long backupEpochSeconds, long poolAwaiting, long poolBlockingMillis) {
        return "load_shed_total " + loadShed.get() + "\n"
                + "idempotency_conflict_total " + idempotencyConflict.get() + "\n"
                + "dependency_timeout_total " + dependencyTimeout.get() + "\n"
                + "kafka_publish_failed_total " + kafkaPublishFailed.get() + "\n"
                + "ai_fallback_total " + aiFallback.get() + "\n"
                + "backup_last_success_timestamp " + backupEpochSeconds + "\n"
                + "db_pool_awaiting " + poolAwaiting + "\n"
                + "db_pool_blocking_ms " + poolBlockingMillis + "\n"
                + "http_responses_2xx_total " + http2xx.get() + "\n"
                + "http_responses_4xx_total " + http4xx.get() + "\n"
                + "http_responses_5xx_total " + http5xx.get() + "\n";
    }
}
