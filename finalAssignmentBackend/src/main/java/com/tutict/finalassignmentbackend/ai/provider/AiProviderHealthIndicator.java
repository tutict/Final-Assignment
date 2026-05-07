package com.tutict.finalassignmentbackend.ai.provider;

import org.springframework.boot.health.contributor.Health;
import org.springframework.boot.health.contributor.HealthIndicator;
import org.springframework.stereotype.Component;

import java.time.Duration;
import java.util.LinkedHashMap;
import java.util.Map;

@Component("aiProvidersHealthIndicator")
public class AiProviderHealthIndicator implements HealthIndicator {

    private final AiProviderRegistry registry;

    public AiProviderHealthIndicator(AiProviderRegistry registry) {
        this.registry = registry;
    }

    @Override
    public Health health() {
        Map<String, ProviderHealth> providerHealth = registry.providerHealth()
                .timeout(Duration.ofSeconds(5))
                .onErrorReturn(Map.<String, ProviderHealth>of())
                .block(Duration.ofSeconds(5));
        Map<String, String> statuses = new LinkedHashMap<>();
        if (providerHealth != null) {
            providerHealth.forEach((provider, health) -> statuses.put(provider, health.status()));
        }
        return Health.up()
                .withDetails(statuses)
                .build();
    }
}
