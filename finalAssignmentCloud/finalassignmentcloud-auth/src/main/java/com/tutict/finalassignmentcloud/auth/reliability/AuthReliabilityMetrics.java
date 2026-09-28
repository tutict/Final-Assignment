package com.tutict.finalassignmentcloud.auth.reliability;

import io.micrometer.core.instrument.Counter;
import io.micrometer.core.instrument.MeterRegistry;
import org.springframework.stereotype.Component;

@Component
public class AuthReliabilityMetrics {

    private final Counter dependencyTimeout;

    public AuthReliabilityMetrics(MeterRegistry registry) {
        this.dependencyTimeout = Counter.builder("dependency_timeout_total").register(registry);
    }

    public void dependencyTimeout() {
        dependencyTimeout.increment();
    }
}
