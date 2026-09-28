package com.tutict.finalassignmentcloud.ai.reliability;

import static org.junit.jupiter.api.Assertions.assertEquals;

import io.micrometer.core.instrument.simple.SimpleMeterRegistry;
import org.junit.jupiter.api.Test;

class AiFallbackMetricsTest {

    @Test
    void registersTheFallbackCounter() {
        SimpleMeterRegistry registry = new SimpleMeterRegistry();
        AiFallbackMetrics metrics = new AiFallbackMetrics(registry);
        assertEquals(0.0, registry.get("ai_fallback_total").counter().count());
        metrics.increment();
        assertEquals(1.0, registry.get("ai_fallback_total").counter().count());
    }
}