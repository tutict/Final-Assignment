package com.tutict.finalassignmentbackend.ai.chat;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Service;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

import java.time.Duration;
import java.util.List;
import java.util.concurrent.ThreadLocalRandom;

@Service
@ConditionalOnProperty(name = "ai.provider.primary", havingValue = "mock", matchIfMissing = true)
public class MockAiProvider implements AiStreamProvider {

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

    MockAiProvider(List<String> tokens, Duration minDelay, Duration maxDelay) {
        this.tokens = List.copyOf(tokens);
        this.minDelay = minDelay;
        this.maxDelay = maxDelay;
    }

    @Override
    public Flux<ChatStreamEvent> stream(
            AiChatStreamRequest request,
            String sessionKey,
            String messageId
    ) {
        Flux<ChatStreamEvent> tokenEvents = Flux.fromIterable(tokens)
                .concatMap(token -> Mono.delay(randomDelay())
                        .thenReturn(ChatStreamEvent.token(sessionKey, messageId, token)));

        return tokenEvents
                .concatWithValues(ChatStreamEvent.done(sessionKey, messageId))
                .doOnCancel(() -> logger.info(
                        "Mock AI provider stream canceled. sessionKey={}, messageId={}",
                        sessionKey,
                        messageId
                ));
    }

    private Duration randomDelay() {
        long minMillis = Math.max(1, minDelay.toMillis());
        long maxMillis = Math.max(minMillis, maxDelay.toMillis());
        return Duration.ofMillis(ThreadLocalRandom.current().nextLong(minMillis, maxMillis + 1));
    }
}

interface AiStreamProvider {
    Flux<ChatStreamEvent> stream(
            AiChatStreamRequest request,
            String sessionKey,
            String messageId
    );
}
