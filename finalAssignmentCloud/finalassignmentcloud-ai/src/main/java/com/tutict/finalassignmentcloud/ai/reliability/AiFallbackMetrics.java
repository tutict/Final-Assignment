package com.tutict.finalassignmentcloud.ai.reliability;

import io.micrometer.core.instrument.Counter;
import io.micrometer.core.instrument.MeterRegistry;
import org.springframework.stereotype.Component;

@Component
public class AiFallbackMetrics {

    private final Counter counter;

    public AiFallbackMetrics(MeterRegistry registry) {
        this.counter = Counter.builder("ai_fallback_total").register(registry);
    }

    public void increment() {
        counter.increment();
    }
}
