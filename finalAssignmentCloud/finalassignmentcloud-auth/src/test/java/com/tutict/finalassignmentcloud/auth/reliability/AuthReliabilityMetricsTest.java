package com.tutict.finalassignmentcloud.auth.reliability;

import static org.junit.jupiter.api.Assertions.assertEquals;

import io.micrometer.core.instrument.simple.SimpleMeterRegistry;
import org.junit.jupiter.api.Test;

class AuthReliabilityMetricsTest {

    @Test
    void dependencyTimeoutIncrements() {
        SimpleMeterRegistry registry = new SimpleMeterRegistry();
        AuthReliabilityMetrics metrics = new AuthReliabilityMetrics(registry);
        metrics.dependencyTimeout();
        assertEquals(1d, registry.get("dependency_timeout_total").counter().count());
    }
}
