package com.tutict.finalassignmentbackend.ai.chat;

import com.tutict.finalassignmentbackend.ai.provider.AiProviderProperties;
import com.tutict.finalassignmentbackend.ai.provider.AiToken;
import org.springframework.stereotype.Component;
import reactor.core.publisher.Flux;

import java.time.Duration;
import java.util.function.Supplier;

/**
 * FIFO limiter shared by Ollama chat streams and embeddings.
 */
@Component
public class OllamaSlotLimiter {

    public static final String TIMEOUT_MESSAGE = FairSlotLimiter.TIMEOUT_MESSAGE;
    public static final String FULL_MESSAGE = FairSlotLimiter.FULL_MESSAGE;

    private final FairSlotLimiter delegate;

    public OllamaSlotLimiter(AiProviderProperties properties) {
        this(
                properties.getOllama().getSlots(),
                properties.getOllama().getMaxQueue(),
                properties.getOllama().getQueueTimeout()
        );
    }

    public OllamaSlotLimiter(int slots, int maxQueue, Duration waitTimeout) {
        this.delegate = new FairSlotLimiter(slots, maxQueue, waitTimeout);
    }

    public Flux<AiToken> protect(Flux<AiToken> work) {
        return delegate.protect(work);
    }

    public <T> T call(Supplier<T> work) {
        return delegate.call(work);
    }

    int queuedCount() {
        return delegate.queuedCount();
    }

    int usedCount() {
        return delegate.usedCount();
    }
}
