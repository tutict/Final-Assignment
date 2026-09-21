package com.tutict.finalassignmentbackend.ai.chat;

import com.tutict.finalassignmentbackend.ai.provider.AiProviderProperties;
import com.tutict.finalassignmentbackend.ai.provider.AiToken;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;
import reactor.core.publisher.Flux;

import java.time.Duration;
import java.util.function.Supplier;

/**
 * Wider HTTP slot pool for the system-level OpenAI-compatible endpoint.
 * Chat generation and external embeddings share this limiter.
 */
@Component
public class ExternalApiSlotLimiter {

    public static final String TIMEOUT_MESSAGE = FairSlotLimiter.TIMEOUT_MESSAGE;
    public static final String FULL_MESSAGE = FairSlotLimiter.FULL_MESSAGE;

    private final FairSlotLimiter delegate;

    @Autowired
    public ExternalApiSlotLimiter(AiProviderProperties properties) {
        this(
                properties.getOpenaiCompatible().getSlots(),
                properties.getOpenaiCompatible().getMaxQueue(),
                properties.getOpenaiCompatible().getQueueTimeout()
        );
    }

    public ExternalApiSlotLimiter(int slots, int maxQueue, Duration waitTimeout) {
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
