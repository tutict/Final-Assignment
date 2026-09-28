package com.tutict.finalassignmentcloud.traffic.reliability;

import io.micrometer.core.instrument.Counter;
import io.micrometer.core.instrument.MeterRegistry;
import java.util.concurrent.atomic.AtomicLong;
import java.util.function.Supplier;
import org.springframework.stereotype.Component;

@Component
public class TrafficReliabilityMetrics {

    private final Counter loadShed;
    private final Counter idempotencyConflict;
    private final Counter dependencyTimeout;
    private final Counter http2xx;
    private final Counter http4xx;
    private final Counter http5xx;
    private final AtomicLong backupLastSuccess = new AtomicLong();
    private volatile Supplier<Long> backupReader = () -> backupLastSuccess.get();

    public TrafficReliabilityMetrics(MeterRegistry registry) {
        this.loadShed = Counter.builder("load_shed_total").register(registry);
        this.idempotencyConflict = Counter.builder("idempotency_conflict_total").register(registry);
        this.dependencyTimeout = Counter.builder("dependency_timeout_total").register(registry);
        this.http2xx = Counter.builder("http_responses_2xx_total").register(registry);
        this.http4xx = Counter.builder("http_responses_4xx_total").register(registry);
        this.http5xx = Counter.builder("http_responses_5xx_total").register(registry);
        registry.gauge("backup_last_success_timestamp", this, TrafficReliabilityMetrics::scrapeBackup);
    }

    public void useBackupReader(Supplier<Long> reader) {
        if (reader != null) {
            this.backupReader = reader;
        }
    }

    double scrapeBackup() {
        try {
            Long value = backupReader.get();
            if (value != null && value > 0L) {
                backupLastSuccess.set(value);
            }
        } catch (RuntimeException ignored) {
            // Keep the last good timestamp when the backup table cannot be read.
        }
        return backupLastSuccess.doubleValue();
    }

    public void loadShed() { loadShed.increment(); }
    public void idempotencyConflict() { idempotencyConflict.increment(); }
    public void dependencyTimeout() { dependencyTimeout.increment(); }

    public void noteStatus(int status) {
        if (status >= 200 && status < 300) {
            http2xx.increment();
        } else if (status >= 400 && status < 500) {
            http4xx.increment();
        } else if (status >= 500 && status < 600) {
            http5xx.increment();
        }
    }

    public void backupSucceededAtEpochSeconds(long epochSeconds) {
        backupLastSuccess.set(epochSeconds);
    }
}
