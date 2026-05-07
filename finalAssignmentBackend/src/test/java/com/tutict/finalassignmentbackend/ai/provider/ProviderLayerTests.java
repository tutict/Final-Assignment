package com.tutict.finalassignmentbackend.ai.provider;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.sun.net.httpserver.HttpServer;
import org.junit.jupiter.api.Test;
import org.springframework.boot.health.contributor.Health;
import org.springframework.web.reactive.function.client.WebClient;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

import java.io.IOException;
import java.io.OutputStream;
import java.net.InetSocketAddress;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.util.List;
import java.util.Map;
import java.util.concurrent.atomic.AtomicInteger;

import static org.assertj.core.api.Assertions.assertThat;

class MockAiProviderTest {

    @Test
    void streamsTokensThenCompletionToken() {
        MockAiProvider provider = new MockAiProvider(
                        List.of("a", "b"),
                        Duration.ofMillis(1),
                        Duration.ofMillis(1)
        );

        List<AiToken> tokens = provider.stream(
                        new AiChatPrompt("hello", Map.of()),
                        ProviderLayerTestSupport.options(Duration.ofSeconds(1))
                )
                .collectList()
                .block(Duration.ofSeconds(1));

        assertThat(tokens).extracting(AiToken::text).containsExactly("a", "b", "");
        assertThat(tokens.getLast().finished()).isTrue();
    }
}

class OllamaAiProviderTest {

    @Test
    void streamsOllamaNdjsonAndReportsHealth() throws IOException {
        HttpServer server = HttpServer.create(new InetSocketAddress(0), 0);
        server.createContext("/api/chat", exchange -> {
            byte[] body = """
                    {"message":{"content":"he"},"done":false}
                    {"message":{"content":"llo"},"done":false}
                    {"done":true}
                    """.getBytes(StandardCharsets.UTF_8);
            exchange.getResponseHeaders().add("Content-Type", "application/x-ndjson");
            exchange.sendResponseHeaders(200, body.length);
            try (OutputStream output = exchange.getResponseBody()) {
                output.write(body);
            }
        });
        server.createContext("/api/tags", exchange -> {
            byte[] body = "{}".getBytes(StandardCharsets.UTF_8);
            exchange.sendResponseHeaders(200, body.length);
            try (OutputStream output = exchange.getResponseBody()) {
                output.write(body);
            }
        });
        server.start();
        try {
            AiProviderProperties properties = ProviderLayerTestSupport.properties(
                    "ollama",
                    "noop",
                    Duration.ofSeconds(1)
            );
            properties.getOllama().setBaseUrl("http://localhost:" + server.getAddress().getPort());
            OllamaAiProvider provider = new OllamaAiProvider(
                    properties,
                    WebClient.builder(),
                    new ObjectMapper()
            );

            List<AiToken> tokens = provider.stream(
                            new AiChatPrompt("hello", Map.of()),
                            ProviderLayerTestSupport.options(Duration.ofSeconds(1))
                    )
                    .collectList()
                    .block(Duration.ofSeconds(1));
            ProviderHealth health = provider.health().block(Duration.ofSeconds(1));

            assertThat(tokens).extracting(AiToken::text).containsExactly("he", "llo", "");
            assertThat(tokens.getLast().finished()).isTrue();
            assertThat(health.status()).isEqualTo("UP");
        } finally {
            server.stop(0);
        }
    }
}

class AiProviderRegistryTest {

    @Test
    void switchesActiveProviderFromConfiguration() {
        AiProvider primary = ProviderLayerTestSupport.provider(
                "primary",
                Flux.just(new AiToken("a", true, Map.of()))
        );
        AiProvider secondary = ProviderLayerTestSupport.provider(
                "secondary",
                Flux.just(new AiToken("b", true, Map.of()))
        );
        AiProviderProperties properties = ProviderLayerTestSupport.properties("secondary", "noop", Duration.ofSeconds(1));

        AiProviderRegistry registry = new AiProviderRegistry(
                List.of(primary, secondary, new NoopAiProvider()),
                properties
        );

        assertThat(registry.activeProvider().providerName()).isEqualTo("secondary");
        assertThat(registry.lookup("primary")).isSameAs(primary);
    }

    @Test
    void cachesProviderHealth() {
        AtomicInteger healthCalls = new AtomicInteger();
        AiProvider provider = ProviderLayerTestSupport.provider("primary", Flux.empty(), () -> {
            healthCalls.incrementAndGet();
            return ProviderHealth.up("ok");
        });
        AiProviderRegistry registry = new AiProviderRegistry(
                List.of(provider, new NoopAiProvider()),
                ProviderLayerTestSupport.properties("primary", "noop", Duration.ofSeconds(1))
        );

        registry.health("primary").block(Duration.ofSeconds(1));
        registry.health("primary").block(Duration.ofSeconds(1));

        assertThat(healthCalls).hasValue(1);
    }
}

class ProviderFallbackTest {

    @Test
    void fallsBackWhenPrimaryTimesOut() {
        AiProvider primary = ProviderLayerTestSupport.provider("primary", Flux.never());
        AiProvider fallback = ProviderLayerTestSupport.provider("fallback", Flux.just(
                new AiToken("fallback", false, Map.of()),
                new AiToken("", true, Map.of())
        ));
        AiProviderRegistry registry = new AiProviderRegistry(
                List.of(primary, fallback, new NoopAiProvider()),
                ProviderLayerTestSupport.properties("primary", "fallback", Duration.ofMillis(10))
        );

        List<AiToken> tokens = registry.stream("hello", Map.of())
                .collectList()
                .block(Duration.ofMillis(500));

        assertThat(tokens).extracting(AiToken::text).containsExactly("fallback", "");
        assertThat(tokens.getFirst().metadata()).containsEntry("provider", "fallback");
    }

    @Test
    void opensCircuitAfterFailureThreshold() {
        AtomicInteger primaryCalls = new AtomicInteger();
        AiProvider primary = ProviderLayerTestSupport.provider("primary", Flux.defer(() -> {
            primaryCalls.incrementAndGet();
            return Flux.error(new IllegalStateException("boom"));
        }));
        AiProvider fallback = ProviderLayerTestSupport.provider(
                "fallback",
                Flux.just(new AiToken("fallback", true, Map.of()))
        );
        AiProviderProperties properties = ProviderLayerTestSupport.properties(
                "primary",
                "fallback",
                Duration.ofMillis(50)
        );
        properties.getProvider().setCircuitBreakerFailureThreshold(1);
        AiProviderRegistry registry = new AiProviderRegistry(
                List.of(primary, fallback, new NoopAiProvider()),
                properties
        );

        registry.stream("hello", Map.of()).collectList().block(Duration.ofSeconds(1));
        registry.stream("hello", Map.of()).collectList().block(Duration.ofSeconds(1));

        assertThat(primaryCalls).hasValue(1);
    }
}

class ProviderHealthIndicatorTest {

    @Test
    void exposesProviderStatusesAsHealthDetails() {
        AiProvider ollama = ProviderLayerTestSupport.provider("ollama", Flux.empty(), () -> ProviderHealth.up("ok"));
        AiProvider mock = ProviderLayerTestSupport.provider("mock", Flux.empty(), () -> ProviderHealth.up("ok"));
        AiProvider openAi = ProviderLayerTestSupport.provider(
                "openai-compatible",
                Flux.empty(),
                () -> ProviderHealth.down("disabled")
        );
        AiProviderRegistry registry = new AiProviderRegistry(
                List.of(ollama, mock, openAi, new NoopAiProvider()),
                ProviderLayerTestSupport.properties("mock", "noop", Duration.ofSeconds(1))
        );
        AiProviderHealthIndicator indicator = new AiProviderHealthIndicator(registry);

        Health health = indicator.health();

        assertThat(health.getDetails()).containsEntry("ollama", "UP");
        assertThat(health.getDetails()).containsEntry("mock", "UP");
        assertThat(health.getDetails()).containsEntry("openai-compatible", "DOWN");
    }
}

final class ProviderLayerTestSupport {
    private ProviderLayerTestSupport() {
    }

    static AiGenerationOptions options(Duration timeout) {
        return new AiGenerationOptions(timeout, timeout, 0, null, null, Map.of());
    }

    static AiProviderProperties properties(String primary, String fallback, Duration streamingTimeout) {
        AiProviderProperties properties = new AiProviderProperties();
        properties.getProvider().setPrimary(primary);
        properties.getProvider().setFallback(fallback);
        properties.getProvider().setTimeout(Duration.ofSeconds(1));
        properties.getProvider().setStreamingTimeout(streamingTimeout);
        properties.getProvider().setRetryAttempts(0);
        properties.getProvider().setHealthCacheTtl(Duration.ofSeconds(30));
        return properties;
    }

    static AiProvider provider(String name, Flux<AiToken> stream) {
        return provider(name, stream, () -> ProviderHealth.up(name));
    }

    static AiProvider provider(String name, Flux<AiToken> stream, HealthSupplier healthSupplier) {
        return new AiProvider() {
            @Override
            public String providerName() {
                return name;
            }

            @Override
            public boolean supportsStreaming() {
                return true;
            }

            @Override
            public Flux<AiToken> stream(AiChatPrompt prompt, AiGenerationOptions options) {
                return stream;
            }

            @Override
            public Mono<AiMessage> complete(AiChatPrompt prompt, AiGenerationOptions options) {
                return Mono.just(new AiMessage("", Map.of()));
            }

            @Override
            public Mono<ProviderHealth> health() {
                return Mono.fromSupplier(healthSupplier::get);
            }
        };
    }
}

@FunctionalInterface
interface HealthSupplier {
    ProviderHealth get();
}
