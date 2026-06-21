package com.tutict.finalassignmentcloud.ai.provider;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

import java.time.Duration;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ThreadLocalRandom;

@Component
public class MockAiProvider implements AiProvider {

    private static final Logger logger = LoggerFactory.getLogger(MockAiProvider.class);

    private final List<String> tokens;
    private final Duration minDelay;
    private final Duration maxDelay;

    public MockAiProvider() {
        this(
                List.of("你好", "，我", "是", "Mock", "AI"),
                Duration.ofMillis(50),
                Duration.ofMillis(150)
        );
    }

    public MockAiProvider(List<String> tokens, Duration minDelay, Duration maxDelay) {
        this.tokens = List.copyOf(tokens);
        this.minDelay = minDelay;
        this.maxDelay = maxDelay;
    }

    @Override
    public String providerName() {
        return "mock";
    }

    @Override
    public boolean supportsStreaming() {
        return true;
    }

    @Override
    public Flux<AiToken> stream(AiChatPrompt prompt, AiGenerationOptions options) {
        Flux<AiToken> tokenEvents = Flux.fromIterable(tokens)
                .concatMap(token -> Mono.delay(randomDelay())
                        .thenReturn(new AiToken(token, false, Map.of())));

        return tokenEvents
                .concatWithValues(new AiToken("", true, Map.of()))
                .doOnCancel(() -> logger.info("Mock AI provider stream canceled."));
    }

    @Override
    public Mono<AiMessage> complete(AiChatPrompt prompt, AiGenerationOptions options) {
        return Flux.fromIterable(tokens)
                .collectList()
                .map(parts -> new AiMessage(String.join("", parts), Map.of()));
    }

    @Override
    public Mono<ProviderHealth> health() {
        return Mono.just(ProviderHealth.up("mock provider ready"));
    }

    private Duration randomDelay() {
        long minMillis = Math.max(1, minDelay.toMillis());
        long maxMillis = Math.max(minMillis, maxDelay.toMillis());
        return Duration.ofMillis(ThreadLocalRandom.current().nextLong(minMillis, maxMillis + 1));
    }
}
