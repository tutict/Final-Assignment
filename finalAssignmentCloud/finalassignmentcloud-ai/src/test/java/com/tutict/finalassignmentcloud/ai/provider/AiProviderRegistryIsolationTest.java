package com.tutict.finalassignmentcloud.ai.provider;

import org.junit.jupiter.api.Test;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

import java.time.Duration;
import java.util.List;
import java.util.Map;
import java.util.concurrent.atomic.AtomicInteger;

import static org.assertj.core.api.Assertions.assertThat;

class AiProviderRegistryIsolationTest {

    @Test
    void isolatedCompletionDoesNotTripTheChatCircuitBreaker() {
        AtomicInteger judgeCalls = new AtomicInteger();
        AiProvider primary = new AiProvider() {
            @Override
            public String providerName() {
                return "primary";
            }

            @Override
            public boolean supportsStreaming() {
                return true;
            }

            @Override
            public Flux<AiToken> stream(AiChatPrompt prompt, AiGenerationOptions options) {
                return Flux.just(new AiToken("ok", true, Map.of()));
            }

            @Override
            public Mono<AiMessage> complete(AiChatPrompt prompt, AiGenerationOptions options) {
                judgeCalls.incrementAndGet();
                return Mono.error(new IllegalStateException("judge down"));
            }

            @Override
            public Mono<ProviderHealth> health() {
                return Mono.just(ProviderHealth.up("ok"));
            }
        };
        AiProviderProperties properties = new AiProviderProperties();
        properties.getProvider().setPrimary("primary");
        properties.getProvider().setFallback("noop");
        properties.getProvider().setStreamingTimeout(Duration.ofSeconds(1));
        properties.getProvider().setTimeout(Duration.ofSeconds(1));
        properties.getProvider().setRetryAttempts(0);
        properties.getProvider().setCircuitBreakerFailureThreshold(1);
        AiProviderRegistry registry = new AiProviderRegistry(
                List.of(primary, new NoopAiProvider()),
                properties
        );

        for (int attempt = 0; attempt < 3; attempt++) {
            registry.completeIsolated("judge", new AiGenerationOptions(
                            Duration.ofSeconds(1), Duration.ofSeconds(1), 0, 0.0, 96, null, null, Map.of()))
                    .onErrorResume(error -> Mono.empty())
                    .block(Duration.ofSeconds(1));
        }

        List<AiToken> tokens = registry.stream("hello", Map.of())
                .collectList()
                .block(Duration.ofSeconds(1));
        assertThat(judgeCalls).hasValue(3);
        assertThat(tokens).extracting(AiToken::text).contains("ok");
    }
}
