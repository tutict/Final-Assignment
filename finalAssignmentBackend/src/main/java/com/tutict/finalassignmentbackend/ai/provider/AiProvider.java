package com.tutict.finalassignmentbackend.ai.provider;

import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

public interface AiProvider {

    String providerName();

    boolean supportsStreaming();

    Flux<AiToken> stream(
            AiChatPrompt prompt,
            AiGenerationOptions options
    );

    Mono<AiMessage> complete(
            AiChatPrompt prompt,
            AiGenerationOptions options
    );

    Mono<ProviderHealth> health();
}
