package com.tutict.finalassignmentbackend.ai.provider;

import io.micrometer.core.instrument.MeterRegistry;
import io.micrometer.core.instrument.Metrics;
import io.micrometer.core.instrument.Timer;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

import java.time.Duration;
import java.time.Instant;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicInteger;

@Component
public class AiProviderRegistry {

    private static final Logger logger = LoggerFactory.getLogger(AiProviderRegistry.class);

    private final Map<String, AiProvider> providers;
    private final AiProviderProperties properties;
    private final MeterRegistry meterRegistry;
    private final Map<String, AtomicInteger> failures = new ConcurrentHashMap<>();
    private final Map<String, CachedHealth> healthCache = new ConcurrentHashMap<>();

    public AiProviderRegistry(List<AiProvider> providers,
                              AiProviderProperties properties) {
        this(providers, properties, Metrics.globalRegistry);
    }

    public AiProviderRegistry(List<AiProvider> providers,
                              AiProviderProperties properties,
                              MeterRegistry meterRegistry) {
        this.providers = new LinkedHashMap<>();
        for (AiProvider provider : providers) {
            this.providers.put(normalize(provider.providerName()), provider);
        }
        this.properties = properties;
        this.meterRegistry = meterRegistry;
    }

    public AiProvider lookup(String providerName) {
        return providers.get(normalize(providerName));
    }

    public AiProvider activeProvider() {
        return lookupOrNoop(properties.getProvider().getPrimary());
    }

    public AiProvider fallbackProvider() {
        return lookupOrNoop(properties.getProvider().getFallback());
    }

    public Flux<AiToken> stream(String message, Map<String, Object> metadata) {
        AiGenerationOptions options = AiGenerationOptions.from(properties, metadata);
        AiChatPrompt prompt = new AiChatPrompt(message, metadata);
        return streamWithFallback(activeProvider(), fallbackProvider(), prompt, options);
    }

    public Mono<AiMessage> complete(String message, Map<String, Object> metadata) {
        AiGenerationOptions options = AiGenerationOptions.from(properties, metadata);
        AiChatPrompt prompt = new AiChatPrompt(message, metadata);
        AiProvider primary = activeProvider();
        AiProvider fallback = fallbackProvider();
        if (circuitOpen(primary)) {
            return fallback.complete(prompt, options).map(result -> withProvider(result, fallback.providerName()));
        }
        Timer.Sample sample = Timer.start(meterRegistry);
        return primary.complete(prompt, options)
                .timeout(options.timeout())
                .retry(options.retryAttempts())
                .map(result -> withProvider(result, primary.providerName()))
                .doOnSuccess(ignored -> {
                    resetFailures(primary);
                    recordAiRequest(sample, primary.providerName(), "complete", "success");
                })
                .doOnError(error -> {
                    recordFailure(primary, error);
                    recordAiRequest(sample, primary.providerName(), "complete", "error");
                })
                .onErrorResume(error -> fallback.complete(prompt, options)
                        .timeout(options.timeout())
                        .map(result -> withProvider(result, fallback.providerName())));
    }

    public Mono<Map<String, ProviderHealth>> providerHealth() {
        return Flux.fromIterable(providers.values())
                .flatMap(provider -> health(provider.providerName())
                        .map(health -> Map.entry(provider.providerName(), health)))
                .collectMap(Map.Entry::getKey, Map.Entry::getValue, LinkedHashMap::new);
    }

    public Mono<ProviderHealth> health(String providerName) {
        AiProvider provider = lookup(providerName);
        if (provider == null) {
            return Mono.just(ProviderHealth.down("provider not registered"));
        }
        CachedHealth cached = healthCache.get(provider.providerName());
        Duration ttl = properties.getProvider().getHealthCacheTtl();
        if (cached != null && cached.createdAt().plus(ttl).isAfter(Instant.now())) {
            return Mono.just(cached.health());
        }
        return provider.health()
                .timeout(properties.getProvider().getTimeout())
                .onErrorResume(error -> Mono.just(ProviderHealth.down(error.getMessage())))
                .doOnNext(health -> healthCache.put(provider.providerName(), new CachedHealth(health, Instant.now())));
    }

    private Flux<AiToken> streamWithFallback(
            AiProvider primary,
            AiProvider fallback,
            AiChatPrompt prompt,
            AiGenerationOptions options
    ) {
        if (circuitOpen(primary)) {
            return fallbackStream(fallback, prompt, options, "circuit_open");
        }
        Timer.Sample sample = Timer.start(meterRegistry);
        return primary.stream(prompt, options)
                .timeout(options.streamingTimeout())
                .retry(options.retryAttempts())
                .map(token -> token.withMetadata("provider", primary.providerName()))
                .doOnComplete(() -> {
                    resetFailures(primary);
                    recordAiRequest(sample, primary.providerName(), "stream", "success");
                })
                .doOnError(error -> {
                    recordFailure(primary, error);
                    recordAiRequest(sample, primary.providerName(), "stream", "error");
                })
                .onErrorResume(error -> fallbackStream(fallback, prompt, options, error.getClass().getSimpleName()));
    }

    private Flux<AiToken> fallbackStream(
            AiProvider fallback,
            AiChatPrompt prompt,
            AiGenerationOptions options,
            String reason
    ) {
        return fallback.stream(prompt, options)
                .timeout(options.streamingTimeout())
                .map(token -> token.withMetadata("provider", fallback.providerName())
                        .withMetadata("isFallback", true)
                        .withMetadata("reason", "provider_unavailable")
                        .withMetadata("fallback_reason", reason));
    }

    private boolean circuitOpen(AiProvider provider) {
        int threshold = Math.max(1, properties.getProvider().getCircuitBreakerFailureThreshold());
        return failures.computeIfAbsent(provider.providerName(), ignored -> new AtomicInteger())
                .get() >= threshold;
    }

    private void recordFailure(AiProvider provider, Throwable error) {
        int count = failures.computeIfAbsent(provider.providerName(), ignored -> new AtomicInteger())
                .incrementAndGet();
        logger.warn(
                "AI provider failure. provider={}, failures={}, reason={}",
                provider.providerName(),
                count,
                error.toString()
        );
    }

    private void resetFailures(AiProvider provider) {
        failures.computeIfAbsent(provider.providerName(), ignored -> new AtomicInteger()).set(0);
    }

    private AiProvider lookupOrNoop(String providerName) {
        AiProvider provider = lookup(providerName);
        if (provider != null) {
            return provider;
        }
        AiProvider noop = lookup("noop");
        if (noop == null) {
            throw new IllegalStateException("No AI provider registered for " + providerName + " and noop is missing");
        }
        return noop;
    }

    private String normalize(String providerName) {
        return providerName == null ? "" : providerName.toLowerCase(Locale.ROOT).trim();
    }

    private AiMessage withProvider(AiMessage message, String providerName) {
        Map<String, Object> metadata = new LinkedHashMap<>(message.metadata());
        metadata.put("provider", providerName);
        return new AiMessage(message.text(), metadata);
    }

    private void recordAiRequest(Timer.Sample sample, String providerName, String mode, String status) {
        sample.stop(meterRegistry.timer(
                "ai.request",
                "provider", providerName,
                "mode", mode,
                "status", status
        ));
    }

    private record CachedHealth(ProviderHealth health, Instant createdAt) {
    }
}
