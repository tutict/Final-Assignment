package com.tutict.finalassignmentbackend.ai.provider;

import org.springframework.stereotype.Component;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

import java.util.Map;

@Component
public class NoopAiProvider implements AiProvider {

    @Override
    public String providerName() {
        return "noop";
    }

    @Override
    public boolean supportsStreaming() {
        return true;
    }

    @Override
    public Flux<AiToken> stream(AiChatPrompt prompt, AiGenerationOptions options) {
        return Flux.just(
                new AiToken("AI provider unavailable.", false, Map.of("fallback", true)),
                new AiToken("", true, Map.of("fallback", true))
        );
    }

    @Override
    public Mono<AiMessage> complete(AiChatPrompt prompt, AiGenerationOptions options) {
        return Mono.just(new AiMessage("AI provider unavailable.", Map.of("fallback", true)));
    }

    @Override
    public Mono<ProviderHealth> health() {
        return Mono.just(ProviderHealth.up("noop fallback ready"));
    }
}
